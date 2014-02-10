module ORMivore
  module Entity
    module OtherDSL

      private

      def responsibility(name, responsibility_class)
        raise BadArgumentError, "No responsibility name provided" unless name
        raise BadArgumentError, "No responsibility class provided" unless responsibility_class

        name = name.to_sym

        raise BadArgumentError, "Can not redefine responsibility '#{name}'" if method_defined?(name)

        define_method(name) do
          responsibilities_cache[name] ||= responsibility_class.new(self)
        end
      end

      alias_method :role, :responsibility
    end
  end
end
