module ORMivore
  module Entity
    module OtherDSL
      def new_with_parent(parent, options)
        allocate.tap { |o|
          o.initialize_with_parent(parent, options)
        }
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
