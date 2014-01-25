module ORMivore
  module Entity
    NULL = Object.new.freeze

    module ClassMethods
      ALLOWED_ATTRIBUTE_TYPES = Coercions.constants.map { |sym| Coercions.const_get(sym) }.freeze

      attr_reader :attributes_declaration
      attr_reader :optional_attributes_list

      def attributes_list
        attributes_declaration.keys
      end

      private

      def attributes(declaration)
        @attributes_declaration = declaration.symbolize_keys.freeze
        validate_attributes_declaration
        # @attributes_list = methods.map(&:to_sym)
        @optional_attributes_list ||= []

        attributes_list.map(&:to_s).each do |attr|
          module_eval(<<-EOS)
            def #{attr}
              attribute(:#{attr})
            end
          EOS
          self::Builder.module_eval(<<-EOS)
            def #{attr}
              attributes[:#{attr}]
            end
            def #{attr}=(value)
              attributes[:#{attr}] = value
            end
          EOS
        end
      end

      def optional(*methods)
        @optional_attributes_list = methods.map(&:to_sym)
      end

      # now, really private methods, not part of API

      # TODO figure out how to differenciate private methods that are part of
      # ORMivore API from those that are NOT

      def validate_attributes_declaration
        attributes_declaration.each do |name, type|
          unless ALLOWED_ATTRIBUTE_TYPES.include?(type)
            raise ORMivore::BadArgumentError, "Invalid attribute type #{type.inspect}"
          end
        end
      end
    end

    def self.included(base)
      base.send(:include, Coercions) # how naughty of us
      base.extend(ClassMethods) # not so naughty, but still...

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
      attrs = options.fetch(:attributes, {})

      if @parent
        raise BadArgumentError, 'id should only be provided for root entities' if @id
        raise BadArgumentError, 'Invalid parent' if @parent.class != self.class # is that too much safety?

        @id = @parent.id

        raise InvalidStateError, "Can not initialise repo different from paren't repo" if @repo && parent.repo
        @repo ||= @parent.repo
        @cache = @parent.cache # cache is shared between all entity versions
      else
        raise BadArgumentError, 'Root entity must have id in order to have attributes' unless @id || attrs.empty?
        coerce_id
        @cache = {}
      end

      self.local_attributes = attrs

      validate_absence_of_unknown_attributes
    end

    def attributes
      collect_from_root({}) { |e, acc|
        acc.merge(e.local_attributes)
      }
    end

    def attribute(name)
      name = name.to_sym

      node = find_nearest_node { |e|
        !!e.local_attributes[name]
      }

      attr = node.local_attributes[name]
      attr == NULL ? nil : attr
    end

    def changes
      collect_from_root({}) { |e, acc|
        if e.root?
          acc
        else
          acc.merge(e.local_attributes)
        end
      }
    end

    def changed?
      !!parent
    end

    def attach_repo(r)
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
    attr_reader :local_attributes, :cache # allows changing the hash

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
            attrs_copy[name] = declared_type.coerce(attr_value)
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
