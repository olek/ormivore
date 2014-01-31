module ORMivore
  module Entity
    module AssociationsDSL
      def association_names
        association_descriptions.keys
      end

      def association_descriptions
        @association_descriptions ||= {}
      end

      private

      def many_to_one(name, entity_class, options)
        data = add_association_description(:many_to_one, name, entity_class, options)

        name = name.to_sym
        finder_name = "find_by_id"

        define_method(name) do
          changed = self.association_changes.select { |o| o[:name] == name }.last

          if changed
            changed[:entities].first
          else
            self.cache_association(name) {
              self.repo.family[entity_class].public_send(finder_name, self.attribute(data[:foreign_key]))
            }
          end
        end
      end

      def one_to_many(name, entity_class, options)
        data = add_association_description(:one_to_many, name, entity_class, options)

        name = name.to_sym
        finder_name = "find_all_by_#{data[:foreign_key]}"

        define_method(name) do
          unchanged = self.cache_association(name) {
            self.repo.family[entity_class].public_send(finder_name, self.id)
          }

          AssociationsDSL.apply_changes(self, name, unchanged)
        end
      end

      def many_to_many(name, entity_class, options)
        data = add_association_description(:many_to_many, name, entity_class, options)

        name = name.to_sym
        finder_name = "find_by_ids"

        define_method(name) do
          unchanged = self.cache_association(name) {
            join_entities = public_send(data[:through])
            if join_entities.empty?
              []
            else
              self.repo.family[entity_class].
                public_send(finder_name,
                  join_entities.map { |link| link.attribute(data[:foreign_key]) }.sort
                ).values
            end
          }

          AssociationsDSL.apply_changes(self, name, unchanged)
        end
      end

      # private API

      def add_association_description(type, name, entity_class, options)
        name = name.to_sym
        raise BadArgumentError, "Association #{name} is already defined" if association_names.include?(name)
        raise BadArgumentError, "Association #{name} can not have nil entity class" unless entity_class

        foreign_key = options.fetch(:fk).to_sym

        association_descriptions[name] = {
          type: type,
          entity_class: entity_class,
          foreign_key: foreign_key
        }.tap { |h|
          h[:through] = options.fetch(:through).to_sym if type == :many_to_many
        }
      end

      def self.apply_changes(entity, name, unchanged)
        entity.association_changes.
          select { |o| o[:name] == name }.
          inject(unchanged) { |last, changes|
            case changes[:action]
            when :add
              last + changes[:entities]
            when :remove
              last - changes[:entities]
            else
              fail
            end
          }
      end
    end
  end
end
