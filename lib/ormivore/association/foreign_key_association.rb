module ORMivore
  module Association
    class ForeignKeyAssociation
      def initialize(identity, association_definition, session)
        @identity = identity
        @name = association_definition.as
        @identity_map = session.identity_map(association_definition.from)
        @repo = session.repo(association_definition.to)
      end

      def value
        fk_value = identity_map[identity].attribute(fk_name)
        if fk_value
          repo.find_by_id(fk_value)
        else
          nil
        end
      end

      def set(entity)
        identity_map[identity].apply(fk_name => entity.identity)
      end

      private

      attr_reader :identity, :name, :identity_map, :repo

      def fk_name
        "#{name}_id"
      end
    end
  end
end
