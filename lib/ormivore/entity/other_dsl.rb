module ORMivore
  module Entity
    module OtherDSL
      def new_with_change_processor(parent, change_processor)
        allocate.tap { |o|
          o.initialize_with_change_processor(parent, change_processor)
        }
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

      private

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
    end
  end
end
