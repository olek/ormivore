module ORMivore
  module Entity
    NULL = Object.new.tap { |o|
      def o.to_s; "#{Module.nesting.first.name}::NULL"; end
    }.freeze

    module ClassMethods
      def new_root(options = {})
        allocate.tap { |o|
          o.initialize_root(options)
          o.session.register(o)
        }
      end

      def new_with_change_processor(parent, change_processor)
        allocate.tap { |o|
          o.initialize_with_change_processor(parent, change_processor)
          if o.noop?
            return parent
          else
            parent.dismiss
          end
          o.session.register(o)
        }
      end

      def new_with_attached_repo(parent, repo)
        allocate.tap { |o|
          o.initialize_with_attached_repo(parent, repo)
          parent.dismiss
          o.session.register(o)
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
      # how naughty of us
      base.send(:include, Coercions)
      base.send(:include, Memoize)

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

    attr_reader :id, :identity, :repo, :session

    def dismissed?
      @dismissed[0]
    end

    # disabled default constructor
    def initialize(*args)
      fail "Default factory .new disabled, please use custom factories"
    end

    # constructor for root
    def initialize_root(options = {})
      # immutable
      @id = options[:id]
      @local_attributes = self.class.coerce(options.fetch(:attributes, {}).symbolize_keys).freeze
      @applied_associations = [].freeze
      @applied_fk_associations = [].freeze
      @repo = options[:repo]
      @session = options[:session] || Session::NULL

      # mutable by necessity, ugly workaround to avoid freezing references
      @dismissed = [false]

      # mutable by design (caches)
      @associations_cache = LazyCache.new
      @fk_associations_cache = LazyCache.new

      eager_fetch_associations = options[:associations]
      if eager_fetch_associations
        eager_fetch_associations.each do |name, value|
          @fk_associations_cache.set(name, value)
        end
      end

      raise BadArgumentError, 'Root entity must have id in order to have attributes' unless @id || @local_attributes.empty?
      @id = self.class.coerce_id(@id)

      @identity = @id
      @identity ||= @session.generate_identity(self.class)

      validate_absence_of_unknown_attributes

      freeze
    end

    # constructor for 'revison' nodes
    def initialize_with_change_processor(parent, change_processor)
      shared_initialize(parent) do
        @local_attributes = change_processor.attributes.freeze
        @applied_associations = change_processor.associations.freeze
        @applied_fk_associations = change_processor.fk_associations.freeze
        @repo = @parent.repo
        @session = @parent.session
      end

    end

    # constructor for 'attach repo' nodes
    def initialize_with_attached_repo(parent, repo)
      shared_initialize(parent) do
        @local_attributes = {}.freeze
        @applied_associations = [].freeze
        @applied_fk_associations = [].freeze
        @repo = repo
        @session = @parent.session # NOTE does that even makes sense?

        raise BadArgumentError, 'Can not attach #{parent} to nil repo' unless repo
        raise InvalidStateError,
          'Can not attach #{parent} to #{repo} because it is already attached to #{parent.repo}' if parent.repo

      end
    end

    def attributes
      memoize(:attributes) do
        collect_from_root({}) { |e, acc|
          acc.merge(e.local_attributes)
        }.tap { |o|
          o.each { |k, v|
            o[k] = nil if v == NULL
          }
        }
      end
    end

    def attribute(name)
      raise BadArgumentError, "Missing attribute name" unless name
      memoize("attribute_#{name}") do
        name = name.to_sym

        node = find_nearest_node { |e|
          !!e.local_attributes[name]
        }

        attr = node.local_attributes[name]
        raise BadArgumentError, "Unknown attribute '#{name}' on entity '#{self.class}'" unless attr || self.class.attributes_list.include?(name)

        attr == NULL ? nil : attr
      end
    end

    def changes
      memoize(:changes) do
        collect_from_root({}) { |e, acc|
          unless e.root?
            acc.merge!(e.local_attributes)
          end

          acc
        }
      end
    end

    def lazy_associations
      self.class.association_names.each_with_object({}) { |name, acc|
        ca = cached_association(name, dereference: false)
        if ca
          acc[name] =
            if ca.respond_to?(:dereference_placeholder)
              if association_adjustments.any? { |o| o.name == name }
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

    def fk_association_adjustments
      memoize(:fk_association_adjustments) do
        collect_from_root([]) { |e, acc|
          unless e.root?
            acc.concat(e.applied_fk_associations)
          end

          acc
        }
      end
    end

    def association_adjustments
      memoize(:association_adjustments) do
        collect_from_root([]) { |e, acc|
          unless e.root?
            acc.concat(e.applied_associations)
          end

          acc
        }
      end
    end

    def foreign_key_changes
      ads = self.class.fk_association_definitions
      fk_association_adjustments.
        each_with_object({}) { |o, acc|
          acc[ads[o.name].foreign_key] = o.entities.first.id
        }
    end

    # TODO Ugh. There must be a simpler way to get foreign keys of an entity
    def foreign_keys
      self.class.fk_association_definitions.
        each_with_object({}) { |(association_name, ad), acc|
          fk_accessor = "#{association_name}_id".to_sym
          fk_name = ad.foreign_key
          acc[fk_name] = self.public_send(fk_accessor)
        }
    end

    # 'rails way' name would be 'dirty?' :)
    def changed?
      !!parent
    end

    # ephemeral: in-memory-only, not stored, will disappear without a
    #     trace if discarded
    # durable: persisted in storage, no data loss if discarded
    # revised: was persisted in storage, and then modified/revised, will lose
    #     recent changes if discarded
    def ephemeral?
      !id
    end

    def durable?
      !(ephemeral? || changed?)
    end

    def revised?
      !ephemeral? && changed?
    end

    def dismiss
      # 'functional' sin - dismissing ad object is definitely going to
      # change its behavior, but being able to continue using 'past' versions of
      # object that moved on seems to be even worse
      @dismissed[0] = true

      self
    end

    def apply(attrs)
      raise InvalidStateError, "Dismissed entities can not be modified any longer" if dismissed?
      self.class.new_with_change_processor(self, ChangeProcessor.new(self, attrs).call)
    end

    def current
      session.current(self)
    end

    def attach_repo(r)
      self.class.new_with_attached_repo(self, r)
    end

    def validate
      attrs = attributes
      self.class.attributes_list.each do |attr|
        if attrs[attr].nil? && !self.class.optional_attributes_list.include?(attr)
          raise BadAttributesError, "Missing attribute '#{attr}'"
        end
      end
    end

    def cache_fk_association(name)
      raise BadArgumentError, "Block needed for cache_fk_association" unless block_given?
      fk_associations_cache.cache(name) {
        yield
      }
    end

    def cached_fk_association(name, options = {})
      raise BadArgumentError, "No block needed for cached_fk_association, maybe you meant cache_fk_association?" if block_given?
      fk_associations_cache.get(name, options)
    end

    def fk_association_cached?(name)
      value = cached_fk_association(name, dereference: false)

      if self.class.fk_association_definitions[name]
        value.nil? || !value.respond_to?(:dereference_placeholder)
      else
        !!value
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

    def association_cached?(name)
      value = cached_association(name, dereference: false)

      if self.class.fk_association_definitions[name]
        value.nil? || !value.respond_to?(:dereference_placeholder)
      else
        !!value
      end
    end

    def ==(other)
      return false unless other.class == self.class

      return id == other.id unless ephemeral?
      return false unless other.ephemeral?
      return attributes == other.attributes &&
        foreign_keys == other.foreign_keys &&
        repo == other.repo &&
        session == other.session
    end

    # more strict than ==, because durable entities with same id but different attributes are not considered equal
    def eql?(other)
      return false unless other.class == self.class

      return id == other.id &&
        attributes == other.attributes &&
        foreign_keys == other.foreign_keys &&
        repo == other.repo &&
        session == other.session
    end

    def hash
      return id.hash ^
        attributes.hash ^
        foreign_keys.hash ^
        repo.hash ^
        session.hash
    end

    # for internal use only, not true public API
    def noop?
      local_attributes.empty? && applied_fk_associations.empty? && applied_associations.empty?
    end

    def inspect(options = {})
      verbose = options.fetch(:verbose, true)

      "#<#{self.class.name}".tap { |s|
          s << ' dismissed' if dismissed?
          s <<  (root? ? ' root' : ' derived')
          s << " id=#{id}" if id
          if verbose
            s << " attributes=#{attributes.inspect}" unless attributes.empty?
            s << " lazy_fk_associations=#{inspect_entities_map(lazy_fk_associations)}" unless lazy_fk_associations.empty?
            s << " lazy_associations=#{inspect_entities_map(lazy_associations)}" unless lazy_associations.empty?
            s << " applied_fk_associations=#{inspect_applied_associations(applied_fk_associations)}" unless applied_fk_associations.empty?
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
      encoder['applied_fk_associations'] = @applied_fk_associations
      encoder['applied_associations'] = @applied_associations
      encoder['changes'] = changes
      encoder['association_adjustments'] = association_adjustments
      encoder['fk_associations_cache'] = @fk_associations_cache
      encoder['associations_cache'] = @associations_cache
      encoder['memoize_cache'] = @memoize_cache
    end

    protected

    attr_reader :parent # Read only access
    attr_reader :local_attributes, :applied_associations, :applied_fk_associations # allows changing the hash
    attr_reader :associations_cache, :fk_associations_cache

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

    def freeze
      super

      @local_attributes.freeze
      @applied_fk_associations.freeze
      @applied_associations.freeze
    end

    def shared_initialize(parent)
      # immutable
      @parent = parent
      raise BadArgumentError, 'Invalid parent' if @parent.class != self.class # is that too much safety?
      @id = @parent.id
      @identity = @parent.identity

      yield # non-shared initialize here

      # mutable by necessity, ugly workaround to avoid freezing references
      @dismissed = [false]

      # mutable for the time being
      # TODO move associations_cache to session, right next to identity
      # map, and entities will become 99.999% mutation free ('dismissed'
      # will be the only exception)
      @associations_cache = @parent.associations_cache # associations_cache is shared between all entity versions
      @fk_associations_cache = @parent.fk_associations_cache # fk_associations_cache is shared between all entity versions

      validate_absence_of_unknown_attributes

      freeze
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

    def inspect_applied_associations(aas)
      aas.
        map { |aa|
          "<#{aa.action} #{inspect_entities(aa.entities)}>"
        }.join(', ').prepend('[') << ']'
    end
  end
end
