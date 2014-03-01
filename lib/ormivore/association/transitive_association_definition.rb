module ORMivore
  module Association
    class TransientAssociationDefinition
      def initialize(from, to, as, via, linked_by, association_definitions)
        @from = from or fail
        @to = to or fail
        @as = as or fail
        if via
          fail unless via.length == 2
          @via = via[1] or fail
          @via_nature = via[0] or fail
          fail unless [:essential, :incidental].include?(@via_nature)
        end
        @linked_by = linked_by or fail

        @via_association_definition = association_definitions.detect { |o|
          o.class == AssociationDefinition &&
          o.to == from &&
            o.reverse_as == @via &&
            o.reverse_multiplier == :many
        } or fail "Can not determine via_class for #{self.inspect}"

        freeze
      end

      def matches?(entity_class, name)
        entity_class == from && name == as
      end

      def matches_in_reverse?(entity_class, name)
        false
      end

      def create_association(identity, name, session, options = nil)
        TransitiveAssociationCollection.new(identity, self, via_association_definition, session)
      end

      attr_reader :from, :to, :as, :via, :via_nature, :linked_by, :via_association_definition
    end
  end
end
