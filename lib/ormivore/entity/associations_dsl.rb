module ORMivore
  module Entity
    module AssociationsDSL
      def association_names
        association_descriptions.keys
      end

      def association_descriptions
        @association_descriptions ||= {}
      end

      def foreign_keys
        association_descriptions.map { |k, data|
          data[:foreign_key] if [:many_to_one, :one_to_one].include?(data[:type])
        }.compact
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

        define_method("#{name}_id") do
          changed = self.association_changes.select { |o| o[:name] == name }.last

          if changed
            changed[:entities].first.id
          else
            self.cached_association(name, dereference: false).try(:id)
          end
        end
      end

      alias_method :one_to_one, :many_to_one

      def one_to_many(name, entity_class, options)
        data = add_association_description(:one_to_many, name, entity_class, options)

        name = name.to_sym
        finder_name = "find_all_by_#{data[:foreign_key]}"

        define_method(name) do
          changes = self.association_changes.select { |o| o[:name] == name }
          last_set_with_index = changes.zip(0...changes.length).select { |(o, _)| o[:action] == :set }.last
          changes = changes[last_set_with_index.last..-1] if last_set_with_index

          if last_set_with_index
            unchanged = []
          else
            unchanged = self.cache_association(name) {
              self.repo.family[entity_class].public_send(finder_name, self.id)
            }
          end

          AssociationsDSL.apply_changes(changes, unchanged)
        end
      end

      def many_to_many(name, entity_class, options)
        data = add_association_description(:many_to_many, name, entity_class, options)

        name = name.to_sym
        finder_name = "find_by_ids"

        define_method(name) do
          changes = self.association_changes.select { |o| o[:name] == name }
          last_set_with_index = changes.zip(0...changes.length).select { |(o, _)| o[:action] == :set }.last
          changes = changes[last_set_with_index.last..-1] if last_set_with_index

          if last_set_with_index
            unchanged = []
          else
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
          end

          AssociationsDSL.apply_changes(changes, unchanged)
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
          h[:inverse_of] = options[:inverse_of].to_sym if options[:inverse_of]
        }
      end

      def self.apply_changes(changes, initial)
        changes.inject(initial) { |last, change|
          case change[:action]
          when :add
            last + change[:entities]
          when :remove
            last - change[:entities]
          when :set
            change[:entities]
          else
            fail
          end
        }
      end
    end
  end
end
