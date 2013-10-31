# TODO figure out how to add validation in a nice way
module ORMivore
  module Entity
    module ClassMethods
      ALLOWED_ATTRIBUTE_TYPES = [String, Symbol, Integer, Float].freeze

      attr_reader :attributes_declaration
      attr_reader :optional_attributes_list

      def attributes_list
        attributes_declaration.keys
      end

      def construct(attrs, id)
        id = coerce_id(id)

        coerced_attrs = attrs.symbolize_keys.tap { |h| coerce(h) }.freeze

        base_attributes = coerced_attrs
        dirty_attributes = {}.freeze

        validate_presence_of_proper_attributes(base_attributes, dirty_attributes)

        obj = allocate

        obj.instance_variable_set(:@id, id)
        obj.instance_variable_set(:@base_attributes, base_attributes)
        obj.instance_variable_set(:@dirty_attributes, dirty_attributes)

        # TODO how to do custom validation?
        # validate

        obj
      end

      def validate_presence_of_proper_attributes(base, dirty)
        # doing complicated way first because it is much more memory efficient
        # but it does not allow for good error messages, so if something is
        # wrong, need to proceed to inefficient validation that produces nice
        # messages
        missing = 0
        known_counts = attributes_list.each_with_object([0, 0]) { |attr, acc|
          acc[0] += 1 if base[attr]
          acc[1] += 1 if dirty[attr]
          missing +=1 unless optional_attributes_list.include?(attr) || base[attr] || dirty[attr]
        }

        if missing > 0 || [base.length, dirty.length] != known_counts
          expensive_validate_presence_of_proper_attributes(
            base.merge(dirty)
          )
        end
      end

      def coerce(attrs)
        attrs.each do |name, attr_value|
          declared_type = attributes_declaration[name]
          if declared_type && !attr_value.is_a?(declared_type)
            attrs[name] =
              # TODO thos case statement is not elegant; figure it out
              case declared_type.name
              when Symbol.name
                attr_value.to_sym
              else
                Kernel.public_send(declared_type.name.to_sym, attr_value)
              end
          end
        end
      rescue ArgumentError => e
        raise ORMivore::BadArgumentError.new(e)
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
              @dirty_attributes[:#{attr}] || @base_attributes[:#{attr}]
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
      def expensive_validate_presence_of_proper_attributes(attrs)
        attributes_list.each do |attr|
          unless attrs.delete(attr) || optional_attributes_list.include?(attr)
            raise BadAttributesError, "Missing attribute '#{attr}'"
          end
        end

        raise BadAttributesError, "Unknown attributes #{attrs.inspect}" unless attrs.empty?
      end

      def validate_attributes_declaration
        attributes_declaration.each do |name, type|
          unless ALLOWED_ATTRIBUTE_TYPES.include?(type)
            raise ORMivore::BadArgumentError, "Invalid attribute type #{type.inspect}"
          end
        end
      end

      def coerce_id(value)
        value ? Integer(value) : nil
      rescue ArgumentError
        raise ORMivore::BadArgumentError, "Not a valid id: #{value.inspect}"
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

    attr_reader :id

    def attributes
      all_attributes
    end

    def changes
      @dirty_attributes
    end

    def apply(attrs)
      self.dup.tap { |other|
        other.expand_changes(attrs)
      }
    end

    protected

    # to be used only by #change
    def expand_changes(attrs)
      attrs = attrs.symbolize_keys.tap { |h| self.class.coerce(h) }
      @dirty_attributes = @dirty_attributes.merge(attrs).freeze # melt and freeze, huh
      @all_attributes = nil # it is not valid anymore

      self.class.validate_presence_of_proper_attributes(@base_attributes, @dirty_attributes)
    end

    private

    def all_attributes
      # memory / performance tradeoff can be played with here by keeping
      # all_attributes around or generating it each time
      @all_attributes = @base_attributes.merge(@dirty_attributes)
    end

    def initialize(attrs)
      coerced_attrs = attrs.symbolize_keys.tap { |h| self.class.coerce(h) }.freeze

      @base_attributes = {}.freeze
      @dirty_attributes = coerced_attrs

      self.class.validate_presence_of_proper_attributes(@base_attributes, @dirty_attributes)

      # TODO how to do custom validation?
      # validate
    end
  end
end
