module ORMivore
  module Entity
    module AttributesDSL
      def attributes_declaration
        @attributes_declaration ||= {}.freeze
      end

      def attributes_list
        attributes_declaration.keys
      end

      def optional_attributes_list
        @optional_attributes_list ||= []
      end

      def shorthand_notation
        @shorthand
      end

      private

      def shorthand(shorthand)
        @shorthand = shorthand.to_sym
      end

      def attributes(&block)
        fail unless block_given?
        attribute_builder = AttributeBuilder.new(self)
        attribute_builder.instance_eval(&block)

        @attributes_declaration = attribute_builder.attributes_declaration

        AttributesDSL.validate_attributes_declaration(attributes_declaration)

        define_attribute_accessors
        define_test_factory
      end

      def optional(*methods)
        @optional_attributes_list = methods.map(&:to_sym)
      end

      # really private methods, not part of API/DSL at all

      def define_attribute_accessors
        attributes_list.map(&:to_s).each do |attr|
          module_eval(<<-EOS)
            def #{attr}
              attribute(:#{attr})
            end
          EOS
        end
      end

      def define_test_factory
        attributes_list.map(&:to_s).each do |attr|
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

      def self.validate_attributes_declaration(attributes_declaration)
        attributes_declaration.each do |name, type|
          unless Coercions::ALLOWED_ATTRIBUTE_TYPES.include?(type)
            raise ORMivore::BadArgumentError, "Invalid attribute type #{type.inspect}"
          end
        end
      end

      class AttributeBuilder
        attr_reader :entity_class
        attr_reader :attributes_declaration

        def initialize(entity_class)
          @entity_class = entity_class
          @attributes_declaration = {}
        end

        def string(*args)
          common(args, 'string', Coercions::String)
        end

        def symbol(*args)
          common(args, 'symbol', Coercions::Symbol)
        end

        def integer(*args)
          common(args, 'integer', Coercions::Integer)
        end

        def boolean(*args)
          common(args, 'boolean', Coercions::Boolean)
        end

        def time(*args)
          common(args, 'time', Coercions::Time)
        end

        def big_decimal(*args)
          common(args, 'big_decimal', Coercions::BigDecimal)
        end

        def float(*args)
          common(args, 'float', Coercions::Float)
        end

        private

        def common(args, type, coercion)
          raise BadArgumentError,
            "No attribute name(s) provided for type '#{type}' in entity '#{entity_class}'" if args.empty?
          args.each do |name|
            attributes_declaration[name.to_sym] = coercion
          end
        end
      end
    end
  end
end
