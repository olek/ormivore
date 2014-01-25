module ORMivore
  module Entity
    module Memoize
      def memoize
        method_names = self.public_instance_methods(false)
        yield
        method_names = self.public_instance_methods(false) - method_names

        method_names.each do |method_name|
          memoize_method(method_name)
        end
      end

      private

      def memoize_method(method_name)
        original_method = self.instance_method(method_name)

        cache_name = "#{self.name.demodulize}.#{method_name}".to_sym

        define_method(method_name) do
          entity.cache_with_name(cache_name) {
            original_method.bind(self).call
          }
        end
      end
    end
  end
end
