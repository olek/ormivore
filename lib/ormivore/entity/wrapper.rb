module ORMivore
  module Entity
    module Wrapper
      def initialize(entity)
        @entity = entity
      end

      private

      attr_reader :entity
    end
  end
end
