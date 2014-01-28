module ORMivore
  module Entity
    module DSL
      attr_reader :attributes_declaration
      attr_reader :optional_attributes_list
      attr_reader :associations_class

      def attributes_list
        attributes_declaration.keys
      end

      private

      def attributes(declaration)
        @attributes_declaration = declaration.symbolize_keys.freeze
        DSL.validate_attributes_declaration(attributes_declaration)
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

      def associations(associations_class)
        raise BadArgumentError, "No association class provided" unless associations_class
        raise BadArgumentError, "Wrong association class provided: #{associations_class}" unless associations_class.is_a?(AssociationsDSL)

        @associations_class = associations_class
      end

      def responsibility(name, responsibility_class)
        raise BadArgumentError, "No responsibility name provided" unless name
        raise BadArgumentError, "No responsibility class provided" unless responsibility_class

        raise BadArgumentError, "Can not redefine responsibility '#{name}'" if method_defined?(name)

        define_method(name) do
          var = "@#{name}"
          (rtn = instance_variable_get(var)) ? rtn : instance_variable_set(var, responsibility_class.new(self))
        end
      end

      alias_method :role, :responsibility

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
