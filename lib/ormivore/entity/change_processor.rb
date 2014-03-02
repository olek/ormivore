module ORMivore
  module Entity
    class ChangeProcessor
      def initialize(parent, attributes)
        attributes = attributes.symbolize_keys # copy

        @parent = parent
        @unprocessed_attributes = attributes
      end

      attr_reader :attributes, :fk_identities

      def call
        @attributes = parent.class.coerce(@unprocessed_attributes.symbolize_keys)

        prune_attributes

        self
      end

      private

      attr_reader :parent

      def prune_attributes
        attributes.delete_if { |k, v| v == parent.attribute(k) }
      end
    end
  end
end
