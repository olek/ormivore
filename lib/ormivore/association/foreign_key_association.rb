module ORMivore
  module Association
    class ForeignKeyAssociation
      def initialize(identity, association_definition, session)
        @identity = identity
        @name = association_definition.as
        @fk_name = association_definition.foreign_key_name
        @from_identity_map = session.identity_map(association_definition.from)
        @to_identity_map = session.identity_map(association_definition.to)
        @repo = session.repo(association_definition.to)
      end

      def value
        loaded_associated_entity ||
          ((o = foreign_key_value) && repo.find_by_id(o))
      end

      def set(entity)
        fail unless entity
        fail if entity.dismissed?

        from_identity_map[identity].apply(fk_name => entity.identity)
      end

      def foreign_key_value
        from_identity_map[identity].attribute(fk_name)
      end

      private

      def loaded_associated_entity
        (fkv = foreign_key_value) ? to_identity_map[fkv].pointer : nil
      end

      attr_reader :identity, :name, :from_identity_map, :to_identity_map, :repo, :fk_name
    end
  end
end
