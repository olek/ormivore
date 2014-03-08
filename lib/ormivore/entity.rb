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

      #def new_with_attached_repo(parent, repo)
      #  allocate.tap { |o|
      #    o.initialize_with_attached_repo(parent, repo)
      #    parent.dismiss
      #    o.session.register(o)
      #  }
      #end

      def coerce_id(id)
        Integer(id) if id
      rescue ArgumentError
        raise ORMivore::BadArgumentError, "Not a valid identity: #{@identity.inspect}"
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

    attr_reader :identity, :session

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
      @identity = options[:identity]
      @local_attributes = self.class.coerce(options.fetch(:attributes, {}).symbolize_keys).freeze
      @session = options[:session] || Session::NULL

      # mutable by necessity, ugly workaround to avoid freezing references
      @dismissed = [false]

      raise BadArgumentError, 'Root entity must have id in order to have attributes' unless @identity || @local_attributes.empty?
      @identity = self.class.coerce_id(@identity) || session.generate_identity(self.class)

      validate_absence_of_unknown_attributes

      freeze
    end

    # constructor for 'revison' nodes
    def initialize_with_change_processor(parent, change_processor)
      shared_initialize(parent) do
        @local_attributes = change_processor.attributes.freeze
        @session = @parent.session
      end

    end

    # constructor for 'attach repo' nodes
    #def initialize_with_attached_repo(parent, repo)
    #  shared_initialize(parent) do
    #    @local_attributes = {}.freeze
    #    @repo = repo
    #    @session = @parent.session # NOTE does that even makes sense?

    #    raise BadArgumentError, 'Can not attach #{parent} to nil repo' unless repo
    #    raise InvalidStateError,
    #      'Can not attach #{parent} to #{repo} because it is already attached to #{parent.repo}' if parent.repo

    #  end
    #end

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

        attr = node.local_attributes[name] if node
        raise BadArgumentError, "Unknown attribute '#{name}' on entity '#{self.class}'" unless attr || self.class.attributes_list.include?(name)

        attr == NULL ? nil : attr
      end
    end

    def durable_ancestor
      if ephemeral?
        nil
      elsif durable?
        self
      elsif revised?
        parent.durable_ancestor
      else
        fail "Wait, what state this entity is in??? #{self.inspect}"
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
      identity < 0
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

    def validate
      attrs = attributes
      self.class.attributes_list.each do |attr|
        if attrs[attr].nil? && !self.class.optional_attributes_list.include?(attr)
          raise BadAttributesError, "Missing attribute '#{attr}'"
        end
      end
    end

    def ==(other)
      return false unless other.class == self.class

      return identity == other.identity
    end

    # much more strict than ==
    # entities with same id but different attributes/session are not considered equal
    def eql?(other)
      return false unless other.class == self.class

      return identity == other.identity &&
        attributes == other.attributes &&
        session == other.session
    end

    def hash
      return identity.hash ^
        attributes.hash ^
        session.hash
    end

    # for internal use only, not true public API
    def noop?
      local_attributes.empty?
    end

    def inspect(options = {})
      verbose = options.fetch(:verbose, true)

      "#<#{self.class.name}".tap { |s|
          s << ' dismissed' if dismissed?
          s <<  (root? ? ' root' : ' derived')
          s << " id=#{id}" if id
          if verbose
            s << " attributes=#{attributes.inspect}" unless attributes.empty?
          else
            s << (":0x%08x" % (object_id * 2)) unless root? || id
          end
      } << '>'
    end

    # customizing to_yaml output that otherwise is a bit too long
    def encode_with(encoder)
      encoder['identity'] = @identity
      encoder['local_attributes'] = @local_attributes
      encoder['changes'] = changes
      encoder['fk_identity_changes?'] = fk_identity_changes
      encoder['memoize_cache'] = @memoize_cache
    end

    protected

    attr_reader :parent # Read only access
    attr_reader :local_attributes

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
    end

    def shared_initialize(parent)
      # immutable
      @parent = parent
      raise BadArgumentError, 'Invalid parent' if @parent.class != self.class # is that too much safety?
      @identity = @parent.identity

      yield # non-shared initialize here

      # mutable by necessity, ugly workaround to avoid freezing references
      @dismissed = [false]

      validate_absence_of_unknown_attributes

      freeze
    end

    def validate_absence_of_unknown_attributes
      unknown_attrs = (local_attributes.keys - self.class.attributes_list).each_with_object({}) { |k, acc|
        acc[k] = local_attributes[k]
      }

      raise BadAttributesError, "Unknown attributes #{unknown_attrs.inspect}" unless unknown_attrs.empty?
    end
  end
end
