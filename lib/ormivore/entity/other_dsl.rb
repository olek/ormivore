module ORMivore
  module Entity
    module OtherDSL
      def responsibilities
        @responsibilities ||= [].freeze
      end

      private

      def responsibility(name, responsibility_class)
        raise BadArgumentError, "No responsibility name provided" unless name
        raise BadArgumentError, "No responsibility class provided" unless responsibility_class

        name = name.to_sym

        raise BadArgumentError, "Can not redefine responsibility '#{name}'" if method_defined?(name)

        define_method(name) do
          responsibility_class.new(self)
        end

        memoize_method(name)

        @responsibilities = (responsibilities + [name]).freeze
      end

      alias_method :role, :responsibility
    end
  end
end
