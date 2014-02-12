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
        convert_set_associations_to_add_remove_pairs

        prune_attributes
        prune_associations

        associations.concat(
          generate_through_association_changes +
          generate_reverse_through_association_changes
        )

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
        when :many_to_one, :one_to_one
          raise BadAttributesError, "#{type} association change requires single entity" unless value.is_a?(Entity)
          { name: name, action: :set, entities: [value] }
        else
          raise BadAttributesError,
            "#{type} association change requires array" unless value.respond_to?(:[]) && value.respond_to?(:length)
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
            "#{type} association change requires array with at least one entity" if entities.empty? && action != :set
          raise BadAttributesError,
            "#{type} association change requires array with entities" unless entities.all? {
              |o| o.is_a?(Entity)
            }

          { name: name, action: action, entities: entities }
        end
      end

      def convert_set_associations_to_add_remove_pairs
        # convert set into add/remove commands asking parent for current state of association.
        # TODO public_send here is not awesome. Introduce method on entity like .attribute(name) but for association
        ad = parent.class.association_descriptions
        replacements = associations.
          select { |o| o[:action] == :set }.
          select { |o| ![:many_to_one, :one_to_one].include?(ad[o[:name]][:type]) }.
          map { |o| o.values_at(:name, :action, :entities) }.
          each_with_object([]) do |(name, _, entities), acc|
            current_entities = parent.public_send(name)
            remove_enttities = current_entities - entities
            add_enttities = entities - current_entities

            acc << { name: name, action: :remove, entities: remove_enttities } unless remove_enttities.empty?
            acc << { name: name, action: :add, entities: add_enttities } unless add_enttities.empty?
          end

        associations.delete_if { |o| o[:action] == :set && ![:many_to_one, :one_to_one].include?(ad[o[:name]][:type]) }
        associations.concat(replacements)
      end

      def generate_reverse_through_association_changes
        ad = parent.class.association_descriptions
        associations.
          map { |o| o.values_at(:name, :action, :entities) }.
          each_with_object([]) do |(name, action, entities), acc|
            data = ad[name]
            through = data[:through]
            if through
              source = data[:source]
              through_data = ad[through]
              through_entities = entities.each_with_object([]) { |e, entities_acc|
                # NOTE what if parent or e are ephemeral?
                through_entity =
                  if action == :add
                    parent.repo.family[through_data[:entity_class]].create(
                      through_data[:inverse_of] => parent, source => e)
                  else
                    parent.association(through).detect { |o|
                      o.association(through_data[:inverse_of]) == parent && o.association(source) == e
                    }
                  end
                entities_acc << through_entity
              }
              acc << { name: through, action: action, entities: through_entities }
            end
          end
      end

      # TODO this should be permanently cached somewhere
      def reverse_through_associations_lookup
        ad = parent.class.association_descriptions
        ad.each_with_object({}) { |(name, data), acc|
          data = ad[name]
          through = data[:through]
          if through
            acc[through] ||= []
            acc[through] << [name, data]
          end
        }
      end

      def generate_through_association_changes
        through_lookup = reverse_through_associations_lookup

        associations.
          map { |o| o.values_at(:name, :action, :entities) }.
          each_with_object([]) do |(name, action, entities), acc|
            join_data = through_lookup[name]
            if join_data && !join_data.empty?
              join_data.each do |(target_association, target_association_data)|
                source = target_association_data[:source]
                target_entities = entities.map(&source).compact
                unless target_entities.empty?
                  acc << { name: target_association, action: action, entities: target_entities }
                end
              end
            end
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
        # can not use include? here because it is using == equality
        parent.association_changes.any? { |assoc| assoc.eql?(association) }
      end

      def noop_direct_link_association?(association, data)
        # TODO check for direction of one_to_one, and extract this question to be reusable (at least 3 places have it)
        return false unless [:many_to_one, :one_to_one].include?(data[:type])

        entity = association[:entities].first
        if parent.association_cached?(association[:name])
          current_entity = parent.public_send(association[:name])
          current_entity.eql?(entity)
        else
          if entity.durable?
            parent.public_send("#{association[:name]}_id") == entity.id
          else
            false
          end
        end
      end
    end
  end
end
