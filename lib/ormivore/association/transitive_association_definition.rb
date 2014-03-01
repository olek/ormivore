module ORMivore
  module Association
    class TransientAssociationDefinition
      def initialize(from, to, as, via, linked_by)
        @from = from or fail
        @to = to or fail
        @as = as or fail
        @via = via or fail
        @linked_by = linked_by or fail

        freeze
      end

      def matches?(entity_class, name)
        entity_class == from && name == as
      end

      def matches_in_reverse?(entity_class, name)
        false
      end

      def create_association(identity, name, session, options = nil)
        TransitiveAssociationCoolection.new(identity, name, session)
      end

      attr_reader :from, :to, :as, :via, :linked_by
    end
  end
end
