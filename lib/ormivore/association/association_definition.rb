module ORMivore
  module Association
    class AssociationDefinition
      def initialize(from, to, as, reverse = nil)
        @from = from or fail
        @to = to or fail
        @as = as or fail
        if reverse
          @reverse_as = reverse[1] or fail
          @reverse_multiplier = reverse[0] or fail
          fail unless [:one, :many].include?(@reverse_multiplier)
        end

        freeze
      end

      def type
        :foreign_key
      end

      def foreign_key_name
        :"#{@as}_id"
      end

      def matches?(entity_class, name)
        entity_class == from && name == as
      end

      def matches_in_reverse?(entity_class, name)
        entity_class == to && name == reverse_as
      end

      def create_association(identity, session, options={})
        if options[:reverse]
          if reverse_multiplier == :many
            ReverseForeignKeyAssociationCollection.new(identity, self, session)
          else
            # TODO implement reverse foreign key association
            fail 'Not Impemented yet'
          end
        else
          ForeignKeyAssociation.new(identity, self, session)
        end
      end

      attr_reader :from, :to, :as, :reverse_as, :reverse_multiplier
    end
  end
end
