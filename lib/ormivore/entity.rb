# TODO figure out how to add validation in a nice way
module ORMivore
  module Entity
    module ClassMethods

      attr_reader :attributes_list
      attr_reader :optional_attributes_list

      private

      def attributes(*methods)
        @attributes_list = methods.map(&:to_sym)
        @optional_attributes_list ||= []

        methods.each do |method|
          method = method.to_s
          module_eval(<<-EOS)
            def #{method}
              dirty_attributes[:#{method}] || base_attributes[:#{method}]
            end
          EOS
          self::Builder.module_eval(<<-EOS)
            def #{method}
              attributes[:#{method}]
            end
            def #{method}=(value)
              attributes[:#{method}] = value
            end
          EOS
        end
      end

      def optional(*methods)
        @optional_attributes_list = methods.map(&:to_sym)
      end
    end

    def self.included(base)
      base.extend(ClassMethods)

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

    def attributes
      all_attributes
    end

    attr_reader :id

    def create(attrs, id = nil)
      self.class.new(attrs, id)
    end

    def prototype(attrs)
      if id
        self.class.new(base_attributes, id, dirty_attributes.merge(attrs))
      else
        self.class.new(dirty_attributes.merge(attrs))
      end
    end

    def changes
      dirty_attributes
    end

    protected

    def dirty_attributes=(attrs)
      if dirty_attributes
        raise InvalidStateError, "Dirty attributes already set to #{dirty_attributes.inspect}, can not change to #{attrs}"
      else
        @dirty_attributes = attrs
      end
    end

    private

    attr_reader :base_attributes, :dirty_attributes

    def all_attributes
      # memory / performance tradeoff can be played with here
      base_attributes.merge(dirty_attributes)
    end

    def validate_presence_of_proper_attributes
      attrs = all_attributes

      self.class.attributes_list.each do |attr|
        unless attrs.delete(attr) || self.class.optional_attributes_list.include?(attr)
          raise BadAttributesError, "Missing attribute '#{attr}'"
        end
      end

      raise BadAttributesError, "Unknown attributes #{attrs.inspect}" unless attrs.empty?
    end

    def initialize(attrs, id = nil, dirty_attrs = {})
      @id = coerce_id(id)

      coerced_attrs = attrs.symbolize_keys.tap { |h| coerce(h) }.freeze

      if id
        @base_attributes = coerced_attrs
        @dirty_attributes =
          dirty_attrs.symbolize_keys.tap { |h| coerce(h) }.
            reject { |k, v|
              coerced_attrs[k] == v
            }.freeze
      else
        @base_attributes = {}.freeze
        @dirty_attributes = coerced_attrs
      end

      validate_presence_of_proper_attributes

      validate
    end

    def coerce_id(value)
      value ? Integer(value) : nil
    rescue ArgumentError
      raise ORMivore::BadArgumentError, "Not a valid id: #{value.inspect}"
    end

    def coerce(attrs)
      # override me!
    end
  end
end
