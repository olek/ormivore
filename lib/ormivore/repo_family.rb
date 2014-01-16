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

    private

    def registry
      @registry ||= {}
    end
  end
end
