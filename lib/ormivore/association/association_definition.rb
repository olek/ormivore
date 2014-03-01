module ORMivore
  module Association
    class AssociationDefinition
      def initialize(from, to, as, reverse = nil)
        @from = from or fail
        @to = to or fail
        @as = as or fail
        if reverse
          @reverse_name = reverse[1] or fail
          @reverse_multiplier = reverse[0] or fail
          fail unless [:one, :many].include?(@reverse_multiplier)
        end

        freeze
      end

      def matches?(entity_class, name)
        entity_class == from && name == as
      end

      def matches_in_reverse?(entity_class, name)
        entity_class == to && name == reverse_name
      end

      def create_association(identity, name, session, options={})
        if options[:reverse]
          if reverse_multiplier == :many
            ReverseForeignKeyAssociationCoolection.new(identity, name, session)
          else
            # TODO implement reverse foreign key association
            fail 'Not Impemented yet'
          end
        else
          ForeignKeyAssociation.new(identity, name, session)
        end
      end

      attr_reader :from, :to, :as, :reverse_name, :reverse_multiplier
    end
  end
end
