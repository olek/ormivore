module ORMivore
  module Entity
    NULL = Object.new.tap { |o|
      def o.to_s
        "ORMivore::Entity::NULL"
      end
    }.freeze

    def self.included(base)
      base.send(:include, Coercions) # how naughty of us

      # not so naughty, but still...
      base.extend(AttributesDSL)
      base.extend(AssociationsDSL)
      base.extend(OtherDSL)

      define_builder_class(base)
    end

    def self.define_builder_class(base)
      base.module_eval(<<-EOS)
        class Builder
          def initialize
            @attributes = {}
          end

          def id
            attributes[:id]
          end

          def adapter=(value)
            @adapter = value
          end

          # FactoryGirl integration point
          def save!
            @attributes = @adapter.create(attributes)
          end

          attr_reader :attributes
        end
      EOS
    end

    attr_reader :id

    def repo
      @repo[0]
    end

    def initialize(options = {})
      @repo = [options[:repo]] # Ugly workaround to avoid freezing repo.
      @id = options[:id]
      @local_attributes = coerce(options.fetch(:attributes, {}).symbolize_keys)
      @local_associations = []
      @cache = {}

      raise BadArgumentError, 'Root entity must have id in order to have attributes' unless @id || @local_attributes.empty?
      coerce_id

      validate_absence_of_unknown_attributes

      freeze
    end

    def initialize_with_parent(parent, options)
      @parent = parent
      raise BadArgumentError, 'Invalid parent' if @parent.class != self.class # is that too much safety?
      repo = options[:repo]
      raise InvalidStateError, "Can not initialise repo different from paren't repo" if repo && @parent.repo

      @local_attributes = coerce(options.fetch(:attributes, {}).symbolize_keys)
      @local_associations = options.fetch(:associations, []).map(&:symbolize_keys)

      @id = @parent.id
      repo ||= @parent.repo
      @cache = @parent.cache # cache is shared between all entity versions

      validate_absence_of_unknown_attributes
      validate_association_changes unless @local_associations.empty?

      prune_applied_attributes
      prune_applied_associations
      set_foreign_key_for_direct_link_associations
      # TODO still need to reset association when fk for it changes

      @repo = [repo] # Ugly workaround to avoid freezing repo.

      freeze
    end

    # TODO local memoize?
    def attributes
      collect_from_root({}) { |e, acc|
        acc.merge(e.local_attributes)
      }.tap { |o|
        o.each { |k, v|
          o[k] = nil if v == NULL
        }
      }
    end

    # TODO local memoize?
    def attribute(name)
      name = name.to_sym

      node = find_nearest_node { |e|
        !!e.local_attributes[name]
      }

      attr = node.local_attributes[name]
      raise BadArgumentError, "Unknown attribute #{name}" unless attr || self.class.attributes_list.include?(name)

      attr == NULL ? nil : attr
    end

    # TODO local memoize?
    def changes
      collect_from_root({}) { |e, acc|
        unless e.root?
          acc.merge!(e.local_attributes)
        end

        acc
      }
    end

    # TODO local memoize?
    def association_changes
      collect_from_root([]) { |e, acc|
        unless e.root?
          acc.concat(e.local_associations)
        end

        acc
      }
    end

    def changed?
      !!parent
    end

    def attach_repo(r)
      # teaching old dog new tricks here is not great, but it is lesser of 2
      # evils - it woud be really bad to have 2 entities in same time line to
      # have different repos
      collect_from_root(nil) do |e|
        e.repo = r
      end

      self
    end

    def apply(attrs, association = nil)
      applied = self.class.new_with_parent(self, attributes: attrs, associations: [association].compact)

      applied.noop? ? self : applied
    end

    def validate
      attrs = attributes
      self.class.attributes_list.each do |attr|
        unless attrs.delete(attr) != nil || self.class.optional_attributes_list.include?(attr)
          raise BadAttributesError, "Missing attribute '#{attr}'"
        end
      end

      raise BadAttributesError, "Unknown attributes #{attrs.inspect}" unless attrs.empty?
    end

    def cache_with_name(cache_name)
      cache_name = cache_name.to_sym
      already_cached = cache[cache_name]

      if already_cached
        already_cached
      else
        cache[cache_name] = yield
      end
    end

    def inspect
      "#<#{self.class.name} id=#{id}, attributes=#{local_attributes.inspect}, associations=#{local_associations.inspect}, parent=#{parent.inspect}>"
    end

    protected

    attr_reader :parent # Read only access
    attr_reader :local_attributes, :local_associations, :cache # allows changing the hash

    def repo=(value)
      raise InvalidStateError, "Can not attach repo second time" if repo
      @repo[0] = value
    end

    def root?
      !parent
    end

    def collect_from_root(acc, &block)
      if parent
        yield(self, parent.collect_from_root(acc, &block))
      else
        yield(self, acc)
      end
    end

    def find_nearest_node(&block)
      if yield(self)
        self
      else
        if parent
          parent.find_nearest_node(&block)
        else
          self
        end
      end
    end

    def noop?
      local_attributes.empty? && local_associations.empty?
    end

    private

    def freeze
      super

      @local_attributes.freeze
      @local_associations.freeze
    end

    def validate_absence_of_unknown_attributes
      unknown_attrs = (local_attributes.keys - self.class.attributes_list).each_with_object({}) { |k, acc|
        acc[k] = local_attributes[k]
      }

      raise BadAttributesError, "Unknown attributes #{unknown_attrs.inspect}" unless unknown_attrs.empty?
    end

    def validate_association_changes
      local_associations.each do |associations|
        validate_single_association_changes(associations)
      end
    end

    def validate_single_association_changes(associations)
      name = associations[:name]
      action = associations[:action]
      entities = associations[:entities]
      entities = associations[:entities] = [*entities]

      raise BadAttributesError, "Unknown association name '#{name}'" unless self.class.association_names.include? name
      raise BadAttributesError, "Unknown action '#{name}'" unless [:set, :add, :remove].include? action
      if action == :set
        raise BadAttributesError, "Too many entities for #{action} '#{name}'" unless entities.length < 2
      else
        raise BadAttributesError, "Missing entities #{action} '#{name}'" if entities.empty?
      end
    end

    def coerce(attrs)
      attrs.each do |name, attr_value|
        declared_type = self.class.attributes_declaration[name]
        if declared_type && !attr_value.is_a?(declared_type)
          if attr_value.nil? || attr_value == NULL
            attrs[name] = NULL
          else
            attrs[name] = declared_type.coerce(attr_value)
          end
        end
      end
    rescue ArgumentError => e
      raise ORMivore::BadArgumentError.new(e)
    end

    def coerce_id
      @id = Integer(@id) if @id
    rescue ArgumentError
      raise ORMivore::BadArgumentError, "Not a valid id: #{@id.inspect}"
    end

    def prune_applied_attributes
      local_attributes.delete_if { |k, v| v == parent.attribute(k) }
    end

    def prune_applied_associations
      @local_associations.delete_if do |association|
        data = self.class.association_descriptions[association[:name]]
        raise BadArgumentError, "Unknown association '#{association[:name]}'" unless data
        return true if noop_direct_link_association?(association, data)

        association_already_present?(association)
      end
    end

    def set_foreign_key_for_direct_link_associations
      local_associations.each do |association|
        data = self.class.association_descriptions[association[:name]]

        # TODO should work with one_to_one(direct) in the future too
        next if data[:type] != :many_to_one

        entity = association[:entities].first
        fk = data[:foreign_key]
        if local_attributes[fk]
          # TODO validation in setter? Questionable...
          raise BadArgumentError,
            "Setting both foreign key attribute '#{fk}'and corresponding association '#{data[:name]}'is not allowed"
        end

        # NOTE assuming entity has id already
        local_attributes[fk] = entity.id
      end
    end

    def association_already_present?(association)
      parent.association_changes.include?(association)
    end

    def noop_direct_link_association?(association, data)
      # TODO should work with one_to_one(direct) in the future too
      return false if data[:type] != :many_to_one

      entity = association[:entities].first
      fk = data[:foreign_key]
      attribute(fk) == entity.id
    end
  end
end
