module ORMivore
  module Entity
    module Memoize
      module ClassMethods
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

          define_method(method_name) do
            memoize(method_name) {
              original_method.bind(self).call
            }
          end
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
      end

      def memoize(name)
        name = name.to_sym
        @memoize_cache ||= {}
        already_cached = @memoize_cache[name]

        if already_cached
          already_cached
        else
          @memoize_cache[name] = yield
        end
      end

      def memoized?(name)
        name = name.to_sym
        @memoize_cache ||= {}
        !!@memoize_cache[name]
      end

      def freeze
        @memoize_cache ||= {}
        super
      end
    end
  end
end
