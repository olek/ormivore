module ORMivore
  module RepoFamily
    def add(repo, entity_class)
      registry[entity_class] = repo
    end

    def [](entity_class)
      registry[entity_class]
    end

    def keys
      registry.keys
    end

    def freeze
      registry.freeze
      super
    end

    def inspect(options = {})
      verbose = options.fetch(:verbose, false)

      "#<#{self.class.name}".tap { |s|
          if verbose
            s << " registry=#{registry}"
          else
            s << (":0x%08x" % (object_id * 2))
          end
      } << '>'
    end

    # customizing to_yaml output
    def encode_with(encoder)
      encoder['registry'] = registry
    end

    private

    def registry
      @registry ||= {}
    end
  end
end
