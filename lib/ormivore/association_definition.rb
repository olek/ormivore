module ORMivore
  class AssociationDefinition
    def initialize(from, to, as, inverse = nil)
      @from = from
      @to = to
      @as = as
      if inverse
        @inverse_name = inverse[1]
        @inverse_multiplier = inverse[0]
        fail unless [:one, :many].include?(@inverse_multiplier)
      end

      freeze
    end

    attr_reader :from, :to, :as, :inverse_name, :inverse_multiplier
  end
end
