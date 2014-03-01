module ORMivore
  module Association
    class AssociationDefinition
      def initialize(from, to, as, reverse = nil)
        @from = from
        @to = to
        @as = as
        if reverse
          @reverse_name = reverse[1]
          @reverse_multiplier = reverse[0]
          fail unless [:one, :many].include?(@reverse_multiplier)
        end

        freeze
      end

      attr_reader :from, :to, :as, :reverse_name, :reverse_multiplier
    end
  end
end
