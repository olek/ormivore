module ORMivore
  module Entity
    module AttributesDSL
      attr_reader :attributes_declaration
      attr_reader :optional_attributes_list

      def attributes_list
        attributes_declaration.keys
      end

      private

      def attributes(declaration)
        @attributes_declaration = declaration.symbolize_keys.freeze
        AttributesDSL.validate_attributes_declaration(attributes_declaration)
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

      # really private methods, not part of API/DSL at all

      def self.validate_attributes_declaration(attributes_declaration)
        attributes_declaration.each do |name, type|
          unless Coercions::ALLOWED_ATTRIBUTE_TYPES.include?(type)
            raise ORMivore::BadArgumentError, "Invalid attribute type #{type.inspect}"
          end
        end
      end
    end
  end
end
