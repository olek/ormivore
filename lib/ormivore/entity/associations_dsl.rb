module ORMivore
  module Entity
    module AssociationsDSL
      def association_names
        association_descriptions.keys
      end

      def association_descriptions
        @association_descriptions ||= {}
      end

      def foreign_key_association_descriptions
        @fkad ||= association_descriptions.each_with_object({}) { |(k, data), acc|
          acc[k] = data if [:many_to_one, :one_to_one].include?(data[:type])
        }
      end

      def foreign_keys
        @fks ||= foreign_key_association_descriptions.map { |k, v| v[:foreign_key] }
      end

      private

      def many_to_one(name, entity_class, options)
        add_association_description(:many_to_one, name, entity_class, options)

        name = name.to_sym

        define_method(name) do
          changed = self.association_changes.select { |o| o[:name] == name }.last

          if changed
            changed[:entities].first
          else
            self.cache_association(name) {
              self.cached_association(name, dereference: true)
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

        define_method(name) do
          changes = self.association_changes.select { |o| o[:name] == name }

          unchanged = 
            if ephemeral?
              []
            else
              self.cache_association(name) {
                foreign_key =
                  if data[:inverse_of]
                    data[:entity_class].association_descriptions[data[:inverse_of]][:foreign_key]
                  else
                    data[:foreign_key] or raise InvalidStateError, "Missing foreign key for association '#{name}' in #{self.inspect}"
                  end
                self.repo.family[entity_class].send('find_all_by_attribute', foreign_key, self.id)
              }
            end

          AssociationsDSL.apply_changes(changes, unchanged)
        end
      end

      def many_to_many(name, entity_class, options)
        data = add_association_description(:many_to_many, name, entity_class, options)

        name = name.to_sym

        define_method(name) do
          changes = self.association_changes.select { |o| o[:name] == name }
          last_set_with_index = changes.zip(0...changes.length).select { |(o, _)| o[:action] == :set }.last
          changes = changes[last_set_with_index.last..-1] if last_set_with_index

          if last_set_with_index
            unchanged = []
          else
            unchanged = self.cache_association(name) {
              # TODO this roundabout dance about getting association as in DB is ugly
              public_send(data[:through]) # initiate query
              join_entities = cached_association(data[:through]) # pull value as it is in DB without changes applied
              if join_entities.empty?
                []
              else
                join_entities.map { |link| link.association(data[:source]) }.sort_by(&:id)
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

        association_descriptions[name] = {
          type: type,
          entity_class: entity_class
        }.tap { |h|
          h[:through] = options.fetch(:through).to_sym if type == :many_to_many
          h[:inverse_of] = options[:inverse_of].to_sym if options[:inverse_of]
          h[:foreign_key] = options[:fk].to_sym if options[:fk]
          h[:source] = options[:source].to_sym if options[:source]
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
