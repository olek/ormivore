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

    # constructor for root
    def initialize(options = {})
      @repo = [options[:repo]] # Ugly workaround to avoid freezing repo.
      @id = options[:id]
      @local_attributes = self.class.coerce(options.fetch(:attributes, {}).symbolize_keys)
      @applied_associations = []
      @associations_cache = LazyCache.new
      @memoize_cache = {}

      associations = options[:associations]
      if associations
        associations.each do |name, value|
          @associations_cache.set(name, value)
        end
      end

      raise BadArgumentError, 'Root entity must have id in order to have attributes' unless @id || @local_attributes.empty?
      @id = self.class.coerce_id(@id)

      validate_absence_of_unknown_attributes

      freeze
    end

    def initialize_with_change_processor(parent, change_processor)
      @parent = parent
      raise BadArgumentError, 'Invalid parent' if @parent.class != self.class # is that too much safety?

      @local_attributes = change_processor.attributes
      @applied_associations = change_processor.associations

      @id = @parent.id
      @associations_cache = @parent.associations_cache # associations_cache is shared between all entity versions
      @memoize_cache = {}
      @repo = [@parent.repo] # Ugly workaround to avoid freezing repo.

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
          acc.concat(e.applied_associations)
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
      applied = self.class.new_with_change_processor(self, ChangeProcessor.new(self, attrs, [association].compact).call)

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

    def inspect
      "#<#{self.class.name} id=#{id}, attributes=#{local_attributes.inspect}, " +
        "applied_associations=#{applied_associations.inspect}, parent=#{parent.inspect}>"
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
  end
end
