module ORMivore
  class IdentityMap
    NULL = Object.new.tap do |o|
      def o.to_s; "#{Module.nesting.first.name}::NULL"; end
      def o.[](identity); nil; end
      def o.set(entity); entity; end
      def o.delete(entity); nil; end
      def o.current(entity); entity end
      def o.current_or_set(entity); entity end
    end

    def initialize(entity_class)
      @entity_class = entity_class or fail
      @storage = {}

      freeze
    end

    def [](identity)
      fail unless identity

      storage[@entity_class.coerce_id(identity)]
    end

    def set(entity)
      fail unless entity
      fail unless entity.class == entity_class

      storage[entity.identity] = entity
    end

    def delete(entity)
      fail unless entity
      fail unless entity.class == entity_class

      storage.delete(entity.identity)
    end

    def current(entity)
      fail unless entity
      fail unless entity.class == entity_class

      self[entity.identity]
    end

    def current_or_set(entity)
      fail unless entity
      fail unless entity.class == entity_class

      current(entity) || set(entity)
    end

    private

    attr_reader :entity_class, :storage
  end
end
