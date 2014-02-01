module ORMivore
  module Entity
    class ChangeProcessor
      def initialize(parent, attributes)
        attributes = attributes.symbolize_keys # copy

        @parent = parent
        an = parent.class.association_names
        @unprocessed_attributes = attributes
        @unprocessed_associations = attributes.each_with_object({}) { |(k, _), acc|
          acc[k] = attributes.delete(k) if an.include?(k)
        }
      end

      attr_reader :attributes, :associations

      def call
        @attributes = parent.class.coerce(@unprocessed_attributes.symbolize_keys)
        @associations = convert_associations(@unprocessed_associations)

        prune_attributes
        prune_associations

        self
      end

      private

      attr_reader :parent

      def convert_associations(assoc)
        assoc.each_with_object([]) do |(name, value), acc|
          acc << convert_association(name, value)
        end
      end

      def convert_association(name, value)
        raise BadAttributesError, "Unknown association name '#{name}'" unless parent.class.association_names.include?(name)

        data = parent.class.association_descriptions[name]
        case type = data[:type]
        when :many_to_one
          raise BadAttributesError, "#{type} association change requires single entity" unless value.is_a?(Entity)
          { name: name, action: :set, entities: [value] }
        else
          raise BadAttributesError,
            "#{type} association change requires array" unless value.respond_to?(:[]) && value.respond_to?(:length)
          raise BadAttributesError,
            "#{type} association change requires array with at least one element" unless value.length > 0
          if %w(+ -).include?(value[0].to_s)
            action =
              case value[0].to_sym
              when :+
                :add
              when :-
                :remove
              end
            entities = value[1..-1]
          else
            action = :set
            entities = value
          end

          raise BadAttributesError,
            "#{type} association change requires array with at least one entity" if entities.empty?
          raise BadAttributesError,
            "#{type} association change requires array with entities" unless entities.all? {
              |o| o.is_a?(Entity)
            }

          { name: name, action: action, entities: entities }
        end
      end

      def prune_attributes
        attributes.delete_if { |k, v| v == parent.attribute(k) }
      end

      def prune_associations
        associations.delete_if do |association|
          data = parent.class.association_descriptions[association[:name]]
          raise BadArgumentError, "Unknown association '#{association[:name]}'" unless data
          noop_direct_link_association?(association, data) ||
            association_already_present?(association)
        end
      end

      def association_already_present?(association)
        parent.association_changes.include?(association)
      end

      def noop_direct_link_association?(association, data)
        # TODO should work with one_to_one(direct) in the future too
        return false if data[:type] != :many_to_one

        entity = association[:entities].first
        parent.public_send("#{association[:name]}_id") == entity.id
      end
    end
  end
end