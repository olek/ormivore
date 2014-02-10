module ORMivore
  module Entity
    NULL = Object.new.tap { |o|
      def o.to_s
        "ORMivore::Entity::NULL"
      end
    }.freeze

    module ClassMethods
      def new_with_change_processor(parent, change_processor)
        allocate.tap { |o|
          o.initialize_with_change_processor(parent, change_processor)
        }
      end

      def coerce_id(id)
        Integer(id) if id
      rescue ArgumentError
        raise ORMivore::BadArgumentError, "Not a valid id: #{@id.inspect}"
      end

      def coerce(attrs)
        attrs.each do |name, attr_value|
          declared_type = attributes_declaration[name]
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
    end

    def self.included(base)
      base.send(:include, Coercions) # how naughty of us

      # not so naughty, but still...
      base.extend(ClassMethods)
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

    def dismissed?
      @dismissed[0]
    end

    # constructor for root
    def initialize(options = {})
      # immutable
      @id = options[:id]
      @local_attributes = self.class.coerce(options.fetch(:attributes, {}).symbolize_keys).freeze
      @applied_associations = [].freeze

      # mutable by necessity, ugly workaround to avoid freezing references
      @dismissed = [false]
      @repo = [options[:repo]]

      # mutable by design (caches)
      @associations_cache = LazyCache.new
      @memoize_cache = {}
      @responsibilities_cache = {}
 
      eager_fetch_associations = options[:associations]
      if eager_fetch_associations
        eager_fetch_associations.each do |name, value|
          @associations_cache.set(name, value)
        end
      end

      raise BadArgumentError, 'Root entity must have id in order to have attributes' unless @id || @local_attributes.empty?
      @id = self.class.coerce_id(@id)

      validate_absence_of_unknown_attributes

      freeze
    end

    # constructor for 'change' nodes
    def initialize_with_change_processor(parent, change_processor)
      # immutable
      @parent = parent
      raise BadArgumentError, 'Invalid parent' if @parent.class != self.class # is that too much safety?
      @id = @parent.id

      @local_attributes = change_processor.attributes.freeze
      @applied_associations = change_processor.associations.freeze

      # mutable by necessity, ugly workaround to avoid freezing references
      @dismissed = [false]
      @repo = [@parent.repo]

      # mutable by design (caches)
      @associations_cache = @parent.associations_cache # associations_cache is shared between all entity versions
      @memoize_cache = {}
      @responsibilities_cache = {}

      validate_absence_of_unknown_attributes

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
      name = name.to_sym if name

      node = find_nearest_node { |e|
        !!e.local_attributes[name]
      }

      attr = node.local_attributes[name]
      raise BadArgumentError, "Unknown attribute '#{name}' on entity '#{self.class}'" unless attr || self.class.attributes_list.include?(name)

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

    def lazy_associations
      self.class.association_names.each_with_object({}) { |name, acc|
        ca = cached_association(name, dereference: false)
        if ca
          acc[name] =
            if ca.respond_to?(:dereference_placeholder)
              if association_changes.any? { |o| o[:name] == name }
                public_send(name)
              else
                ca
              end
            else
              public_send(name)
            end
        end
      }
    end

    def association(name)
      name = name.to_sym if name
      raise BadArgumentError, "No association '#{name}' registered." unless self.class.association_names.include?(name)

      public_send(name)
    end

    # TODO local memoize?
    def association_changes
      collect_from_root([]) { |e, acc|
        unless e.root?
          acc.concat(e.applied_associations)
        end

        acc
      }
    end

    def foreign_key_changes
      ad = self.class.foreign_key_association_descriptions
      association_changes.
        select { |o| ad.has_key?(o[:name]) }.
        each_with_object({}) { |o, acc|
          acc[ad[o[:name]][:foreign_key]] = o[:entities].first.id
        }
    end

    # TODO Ugh. There must be a simpler way to get foreign keys of an entity
    def foreign_keys
      self.class.foreign_key_association_descriptions.
        each_with_object({}) { |(association_name, _), acc|
          fk_name = "#{association_name}_id".to_sym
          acc[fk_name] = self.public_send(fk_name)
        }
    end

    def changed?
      !!parent
    end

    def persisted?
      !!id
    end

    def attach_repo(r)
      # teaching old dog new tricks here is not great, but it is lesser of 2
      # evils - it woud be really bad to have 2 entities in same time line to
      # have different repos

      parent.attach_repo(r) if parent
      self.repo = r

      self
    end

    def dismiss
      # another 'functional' sin - dismissing ad object is definitely going to
      # change its behavior, but being able to continue using old versions of
      # already persisted object seems to be even worse
      parent.dismiss if parent
      @dismissed[0] = true

      self
    end

    def apply(attrs)
      raise InvalidStateError, "Dismissed entities can not be modified any longer" if dismissed?
      applied = self.class.new_with_change_processor(self, ChangeProcessor.new(self, attrs).call)

      applied.noop? ? self : applied
    end

    def validate
      attrs = attributes
      self.class.attributes_list.each do |attr|
        if attrs[attr].nil? && !self.class.optional_attributes_list.include?(attr)
          raise BadAttributesError, "Missing attribute '#{attr}'"
        end
      end
    end

    def cache_association(name)
      raise BadArgumentError, "Block needed for cache_association" unless block_given?
      associations_cache.cache(name) {
        yield
      }
    end

    def cached_association(name, options = {})
      raise BadArgumentError, "No block needed for cached_association, maybe you meant cache_association?" if block_given?
      associations_cache.get(name, options)
    end

    def memoize(name)
      name = name.to_sym
      already_cached = memoize_cache[name]

      if already_cached
        already_cached
      else
        memoize_cache[name] = yield
      end
    end

    def eql?(other)
      return false unless other.class == self.class

      return id == other.id if persisted?
      return false if other.persisted?
      return attributes == other.attributes &&
        foreign_keys == other.foreign_keys &&
        repo == other.repo
    end

    alias == eql?

    def hash
      return id.hash if persisted?
      return attributes.hash ^
        foreign_keys.hash ^
        repo.hash
    end

    def inspect(options = {})
      verbose = options.fetch(:verbose, true)

      "#<#{self.class.name}".tap { |s|
          s << ' dismissed' if dismissed?
          s << " root" if root?
          s << " id=#{id}" if id
          if verbose
            s << " attributes=#{attributes.inspect}" unless attributes.empty?
            s << " lazy_associations=#{inspect_entities_map(lazy_associations)}" unless lazy_associations.empty?
            s << " applied_associations=#{inspect_applied_associations(applied_associations)}" unless applied_associations.empty?
          else
            s << (":0x%08x" % (object_id * 2)) unless root? || id
          end
      } << '>'
    end

    # customizing to_yaml output that otherwise is a bit too long
    def encode_with(encoder)
      encoder['id'] = @id
      encoder['local_attributes'] = @local_attributes
      encoder['applied_associations'] = @applied_associations
      encoder['changes'] = changes
      encoder['association_changes'] = association_changes
      encoder['associations_cache'] = @associations_cache
      encoder['memoize_cache'] = @memoize_cache
    end

    protected

    attr_reader :parent # Read only access
    attr_reader :local_attributes, :applied_associations # allows changing the hash
    attr_reader :associations_cache

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
      local_attributes.empty? && applied_associations.empty?
    end

    private

    attr_reader :responsibilities_cache

    def freeze
      super

      @local_attributes.freeze
      @applied_associations.freeze
    end

    def validate_absence_of_unknown_attributes
      unknown_attrs = (local_attributes.keys - self.class.attributes_list).each_with_object({}) { |k, acc|
        acc[k] = local_attributes[k]
      }

      raise BadAttributesError, "Unknown attributes #{unknown_attrs.inspect}" unless unknown_attrs.empty?
    end

    # FIXME all those inspects here smell... find better place for them
    def inspect_entities(entities)
      return 'NIL' unless entities
      if entities.respond_to?(:length)
        entities.map { |e|
          e.inspect(verbose: false)
        }.join(', ').prepend('[') << ']'
      else
        entities.inspect(verbose: false)
      end
    end

    def inspect_entities_map(map)
      map.map { |k, v|
        "#{k.inspect}=>#{inspect_entities(v)}"
      }.join(', ').prepend('{') << '}'
    end

    def inspect_applied_associations(aa)
      aa.
        map { |o| o.values_at(:name, :action, :entities) }.
        map { |(_, action, entities)|
          "<#{action} #{inspect_entities(entities)}>"
        }.join(', ').prepend('[') << ']'
    end
  end
end
