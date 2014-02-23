module ORMivore
  module Entity
    class ChangeProcessor
      def initialize(parent, attributes)
        attributes = attributes.symbolize_keys # copy

        @parent = parent
        fkan = parent.class.fk_association_names
        an = parent.class.association_names
        @unprocessed_attributes = attributes
        @unprocessed_fk_associations = attributes.each_with_object({}) { |(k, _), acc|
          acc[k] = attributes.delete(k) if fkan.include?(k)
        }
        @unprocessed_associations = attributes.each_with_object({}) { |(k, _), acc|
          acc[k] = attributes.delete(k) if an.include?(k)
        }
      end

      attr_reader :attributes, :associations, :fk_associations

      def call
        @attributes = parent.class.coerce(@unprocessed_attributes.symbolize_keys)
        @fk_associations = convert_associations(@unprocessed_fk_associations)
        @associations = convert_associations(@unprocessed_associations)
        convert_set_associations_to_add_remove_pairs

        prune_attributes
        prune_fk_associations
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

        ad = parent.class.association_definitions[name]
        if ad.direct?
          raise BadAttributesError, "#{type} association change requires single entity" unless value.is_a?(Entity)
          AssociationAdjustment.new(name, :set, [value])
        else
          raise BadAttributesError,
            "#{type} association change requires array" unless value.is_a?(Array)
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

          AssociationAdjustment.new(name, action, entities)
        end
      end

      def convert_set_associations_to_add_remove_pairs
        # convert set into add/remove commands asking parent for current state of association.
        # TODO public_send here is not awesome. Introduce method on entity like .attribute(name) but for association
        ads = parent.class.association_definitions
        replacements = associations.
          select { |o| o.action == :set }.
          select { |o| ads[o.name].reverse? }.
          each_with_object([]) do |aa, acc|
            current_entities = parent.public_send(aa.name)
            remove_entities = current_entities - aa.entities
            add_enttities = aa.entities - current_entities

            acc << AssociationAdjustment.new(aa.name, :remove, remove_entities) unless remove_entities.empty?
            acc << AssociationAdjustment.new(aa.name, :add, add_enttities) unless add_enttities.empty?
          end

        associations.delete_if { |o| o.action == :set && ads[o.name].reverse? }
        associations.concat(replacements)
      end

      def generate_reverse_through_association_changes
        ads = parent.class.association_definitions
        associations.
          each_with_object([]) do |aa, acc|
            ad = ads[aa.name]
            through = ad.through
            if through
              source = ad.source
              through_ad = ads[through]
              through_entities = aa.entities.each_with_object([]) { |e, entities_acc|
                # NOTE what if parent or e are ephemeral?
                through_entity =
                  if aa.action == :add
                    parent.repo.family[through_ad.entity_class].create(
                      through_ad.inverse_of => parent, source => e)
                  else
                    parent.association(through).detect { |o|
                      o.association(through_ad.inverse_of) == parent && o.association(source) == e
                    }
                  end
                entities_acc << through_entity
              }
              acc << AssociationAdjustment.new(through, aa.action, through_entities)
            end
          end
      end

      # TODO this should be permanently cached somewhere
      def reverse_through_associations_lookup
        ads = parent.class.association_definitions
        ads.each_with_object({}) { |(name, ad), acc|
          through = ad.through
          if through
            acc[through] ||= []
            acc[through] << [name, ad]
          end
        }
      end

      def generate_through_association_changes
        through_lookup = reverse_through_associations_lookup

        associations.
          each_with_object([]) do |aa, acc|
            join_data = through_lookup[aa.name]
            if join_data && !join_data.empty?
              join_data.each do |(target_association, target_association_definition)|
                source = target_association_definition.source
                target_entities = aa.entities.map(&source).compact
                unless target_entities.empty?
                  acc << AssociationAdjustment.new(target_association, aa.action, target_entities)
                end
              end
            end
          end
      end

      def prune_attributes
        attributes.delete_if { |k, v| v == parent.attribute(k) }
      end

      def prune_fk_associations
        fk_associations.delete_if do |association|
          ad = parent.class.fk_association_definitions[association.name]
          raise BadArgumentError, "Unknown association '#{association.name}'" unless ad

          noop_direct_link_association?(association, ad)
        end
      end

      def prune_associations
        associations.delete_if do |association|
          ad = parent.class.association_definitions[association.name]
          raise BadArgumentError, "Unknown association '#{association.name}'" unless ad

          association_already_present?(association)
        end
      end

      def association_already_present?(association)
        # can not use include? here because it is using == equality
        parent.association_adjustments.any? { |assoc| assoc.eql?(association) }
      end

      def noop_direct_link_association?(association, ad)
        return false unless ad.direct?

        entity = association.entities.first
        if parent.fk_association_cached?(association.name)
          current_entity = parent.public_send(association.name)
          current_entity.eql?(entity)
        else
          if entity.durable?
            parent.public_send("#{association.name}_id") == entity.id
          else
            false
          end
        end
      end
    end
  end
end
