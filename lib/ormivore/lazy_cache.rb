module ORMivore
  class LazyCache
    def initialize
      @cache = {}
      freeze
    end

    def set(cache_name, value)
      # value may be placeholder
      cache_name = cache_name.to_sym
      already_cached = cache[cache_name]

      if already_cached
        raise InvalidStateError, "Can not set value for already cached entry"
      else
        cache[cache_name] = value
      end
    end

    def get(cache_name)
      cache_name = cache_name.to_sym
      already_cached = cache[cache_name]

      if already_cached
        dereference_placeholder(already_cached, cache_name)
      else
        # get should not be used with placeholders
        cache[cache_name] = dereference_placeholder(yield, cache_name)
      end
    end

    def dereference_placeholder(value, cache_name)
      if value.respond_to?(:dereference_placeholder)
        cache[cache_name] = value.dereference_placeholder
      else
        value
      end
    end

    private

    attr_reader :cache
  end
end
