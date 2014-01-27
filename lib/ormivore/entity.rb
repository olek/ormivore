module ORMivore
  module Entity
    NULL = Object.new.tap { |o|
      def o.to_s
        "ORMivore::Entity::NULL"
      end
    }.freeze

    def self.included(base)
      base.send(:include, Coercions) # how naughty of us
      base.extend(DSL) # not so naughty, but still...

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

    attr_reader :id, :repo

    def initialize(options = {})
      @parent = options[:parent]
      @repo = options[:repo]
      @id = options[:id]
      @local_association_changes = options[:association_changes]
      attrs = options.fetch(:attributes, {})

      if @parent
        raise BadArgumentError, 'id should only be provided for root entities' if @id
        raise BadArgumentError, 'Invalid parent' if @parent.class != self.class # is that too much safety?

        @id = @parent.id

        raise InvalidStateError, "Can not initialise repo different from paren't repo" if @repo && parent.repo
        @repo ||= @parent.repo
        @cache = @parent.cache # cache is shared between all entity versions
        @local_association_changes = @local_association_changes.symbolize_keys if @local_association_changes # copy
      else
        raise BadArgumentError, 'Root entity must have id in order to have attributes' unless @id || attrs.empty?
        raise BadArgumentError, 'Association changes should only be provided for non-root entities' if @local_association_changes
        coerce_id
        @cache = {}
      end

      self.local_attributes = attrs

      validate_absence_of_unknown_attributes
      validate_association_changes if @local_association_changes
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
          acc << e.local_association_changes
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

    def apply(attrs)
      attrs = coerce(attrs)
      attrs.delete_if { |k, v| v == attribute(k) }

      attrs.empty? ? self : self.class.new(attributes: attrs, parent: self)
    end

    def change_association(name, action, entities)
      self.class.new(association_changes: { name: name, action: action, entities: entities }, parent: self)
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
      "#<#{self.class.name} id=#{id}, attributes=#{local_attributes.inspect} parent=#{parent.inspect}>"
    end

    protected

    attr_reader :parent # Read only access
    attr_reader :local_attributes, :local_association_changes, :cache # allows changing the hash

    def repo=(repo)
      raise InvalidStateError, "Can not attach repo second time" if @repo
      @repo = repo
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

    private

    def validate_absence_of_unknown_attributes
      unknown_attrs = (local_attributes.keys - self.class.attributes_list).each_with_object({}) { |k, acc|
        acc[k] = local_attributes[k]
      }

      raise BadAttributesError, "Unknown attributes #{unknown_attrs.inspect}" unless unknown_attrs.empty?
    end

    def validate_association_changes
      name = local_association_changes[:name]
      action = local_association_changes[:action]
      entities = local_association_changes[:entities]
      entities = local_association_changes[:entities] = [*entities]

      raise BadAttributesError, "Unknown association name '#{name}'" unless associations.names.include? name
      raise BadAttributesError, "Unknown action '#{name}'" unless [:set, :add, :remove].include? action
      if action == :set
        raise BadAttributesError, "Too many entities for #{action} '#{name}'" unless entities.length < 2
      else
        raise BadAttributesError, "Missing entities #{action} '#{name}'" if entities.empty?
      end
    end

    def local_attributes=(attrs)
      attrs = coerce(attrs)

      @local_attributes = attrs.freeze
    rescue ArgumentError => e
      raise ORMivore::BadArgumentError.new(e)
    end

    def coerce(attrs)
      attrs.symbolize_keys.tap { |attrs_copy|
        attrs_copy.each do |name, attr_value|
          declared_type = self.class.attributes_declaration[name]
          if declared_type && !attr_value.is_a?(declared_type)
            if attr_value.nil? || attr_value == NULL
              attrs_copy[name] = NULL
            else
              attrs_copy[name] = declared_type.coerce(attr_value)
            end
          end
        end
      }
    end

    def coerce_id
      @id = Integer(@id) if @id
    rescue ArgumentError
      raise ORMivore::BadArgumentError, "Not a valid id: #{@id.inspect}"
    end
  end
end
