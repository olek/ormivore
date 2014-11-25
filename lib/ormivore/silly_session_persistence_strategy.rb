module ORMivore
  class SillySessionPersistenceStrategy
    def initialize(session)
      @session = session or fail
    end

    def call
      session.entity_classes.each do |entity_class|
        repo = session.repo(entity_class)
        identity_map = session.identity_map(entity_class)

        identity_map.deleted.each do |entity_to_delete|
          repo.delete(entity_to_delete)
        end

        identity_map.select { |o| o.ephemeral? }.each do |entity_to_insert|
          repo.persist(entity_to_insert.pointer)
        end
      end

      session.entity_classes.each do |entity_class|
        repo = session.repo(entity_class)
        identity_map = session.identity_map(entity_class)

        identity_map.select { |o| o.revised? }.each { |entity_to_update|
          repo.persist(entity_to_update)
        }
      end
    end

    private

    attr_reader :session
  end
end
