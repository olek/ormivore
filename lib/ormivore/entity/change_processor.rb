module ORMivore
  module Entity
    class ChangeProcessor
      def initialize(parent, attributes, associations)
        @parent = parent
        @unprocessed_attributes = attributes
        @unprocessed_associations = associations
      end

      attr_reader :attributes, :associations

      def call
        @attributes = parent.class.coerce(@unprocessed_attributes.symbolize_keys)
        @associations = @unprocessed_associations.map(&:symbolize_keys)

        validate_association_changes unless associations.empty?

        prune_applied_attributes
        prune_applied_associations
        set_foreign_key_for_direct_link_associations
        # TODO still need to reset association when fk for it changes

        self
      end

      private

      attr_reader :parent

      def validate_association_changes
        associations.each do |associations|
          validate_single_association_changes(associations)
        end
      end

      def validate_single_association_changes(associations)
        name = associations[:name]
        action = associations[:action]
        entities = associations[:entities]
        entities = associations[:entities] = [*entities]

        raise BadAttributesError, "Unknown association name '#{name}'" unless parent.class.association_names.include? name
        raise BadAttributesError, "Unknown action '#{name}'" unless [:set, :add, :remove].include? action
        if action == :set
          raise BadAttributesError, "Too many entities for #{action} '#{name}'" unless entities.length < 2
        else
          raise BadAttributesError, "Missing entities #{action} '#{name}'" if entities.empty?
        end
      end

      def prune_applied_attributes
        attributes.delete_if { |k, v| v == parent.attribute(k) }
      end

      def prune_applied_associations
        associations.delete_if do |association|
          data = parent.class.association_descriptions[association[:name]]
          raise BadArgumentError, "Unknown association '#{association[:name]}'" unless data
          return true if noop_direct_link_association?(association, data)

          association_already_present?(association)
        end
      end

      def set_foreign_key_for_direct_link_associations
        associations.each do |association|
          data = parent.class.association_descriptions[association[:name]]

          # TODO should work with one_to_one(direct) in the future too
          next if data[:type] != :many_to_one

          entity = association[:entities].first
          fk = data[:foreign_key]
          if attributes[fk]
            # TODO validation in setter? Questionable...
            raise BadArgumentError,
              "Setting both foreign key attribute '#{fk}'and corresponding association '#{data[:name]}'is not allowed"
          end

          # NOTE assuming entity has id already
          attributes[fk] = entity.id
        end
      end

      def association_already_present?(association)
        parent.association_changes.include?(association)
      end

      def noop_direct_link_association?(association, data)
        # TODO should work with one_to_one(direct) in the future too
        return false if data[:type] != :many_to_one

        entity = association[:entities].first
        fk = data[:foreign_key]
        parent.attribute(fk) == entity.id
      end
    end
  end
end
