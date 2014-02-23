module ORMivore
  class IdentityMap
    def initialize(entity_class)
      @entity_class = entity_class or fail
      @storage = {}

      freeze
    end

    def [](identity)
      fail unless identity

      storage[identity]
    end

    def set(entity)
      fail unless entity
      fail unless entity.class == entity_class
      fail if entity.ephemeral?

      storage[entity.identity] = entity
    end

    def current(entity)
      fail unless entity
      fail unless entity.class == entity_class
      fail if entity.ephemeral?

      self[entity.identity]
    end

    def current_or_set(entity)
      fail unless entity
      fail unless entity.class == entity_class
      fail if entity.ephemeral?

      current(entity) || set(entity)
    end

    private

    attr_reader :entity_class, :storage
  end
end
