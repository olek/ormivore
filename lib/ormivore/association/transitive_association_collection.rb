module ORMivore
  module Association
    class TransitiveAssociationCoolection
      def initialize(identity, association_definition, session)
        @identity = identity
        @name = association_definition.as
        @via = association_definition.via
        @linked_by = association_definition.linked_by
        @identity_map = session.identity_map(association_definition.from)
        @session = session
      end

      def values
        session.association(identity_map[identity], via).values.map { |o|
          session.association(o, linked_by).value
        }.flatten
      end

      private

      attr_reader :identity, :name, :via, :linked_by, :identity_map, :session
    end
  end
end
