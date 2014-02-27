module ORMivore
  module Entity
    class ChangeProcessor
      def initialize(parent, attributes)
        attributes = attributes.symbolize_keys # copy

        @parent = parent
        fkan = parent.class.fk_association_names
        @unprocessed_attributes = attributes
        @unprocessed_fk_identities = attributes.each_with_object({}) { |(k, _), acc|
          acc[k] = attributes.delete(k) if fkan.include?(k)
        }
      end

      attr_reader :attributes, :fk_identities

      def call
        @attributes = parent.class.coerce(@unprocessed_attributes.symbolize_keys)
        @fk_identities = convert_fk_identities

        prune_attributes

        self
      end

      private

      attr_reader :parent

      def convert_fk_identities
        Hash[
          @unprocessed_fk_identities.map do |(name, value)|
            convert_fk_identity(name, value)
          end
        ]
      end

      def convert_fk_identity(name, entity)
        raise BadAttributesError, "Set association change requires single entity" unless entity.is_a?(Entity)

        [name, entity.identity]
      end

      def prune_attributes
        attributes.delete_if { |k, v| v == parent.attribute(k) }
      end
    end
  end
end
