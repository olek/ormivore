module ORMivore
  class LazyCache
    def initialize
      @storage = {}
      freeze
    end

    def set(cache_name, value)
      # value may be placeholder
      cache_name = cache_name.to_sym
      already_cached = storage[cache_name]

      if already_cached
        raise InvalidStateError, "Can not set value for already cached entry"
      else
        storage[cache_name] = value
      end
    end

    def cache(cache_name)
      cache_name = cache_name.to_sym
      already_cached = storage[cache_name]

      value =
        if already_cached
          already_cached
        else
          storage[cache_name] = yield
        end

      dereference_placeholder(value, cache_name)
    end

    def get(cache_name, options = {})
      cache_name = cache_name.to_sym
      value = storage[cache_name]

      if value && options.fetch(:dereference, true)
        dereference_placeholder(value, cache_name)
      else
        value
      end
    end

    private

    attr_reader :storage

    def dereference_placeholder(value, cache_name)
      if value.respond_to?(:dereference_placeholder)
        storage[cache_name] = value.dereference_placeholder
      else
        value
      end
    end
  end
end
