module ORMivore
  module Entity
    module AssociationsDSL
      def fk_association_names
        fk_association_definitions.keys
      end

      def association_names
        association_definitions.keys
      end

      def association_definitions
        @association_definitions ||= {}
      end

      def fk_association_definitions
        @fkad ||= association_definitions.each_with_object({}) { |(k, ad), acc|
          acc[k] = ad if ad.direct?
        }
      end

      def foreign_keys
        @fks ||= fk_association_definitions.map { |k, v| v.foreign_key }
      end

      private

      def many_to_one(name, entity_class, options)
        add_association_description(:many_to_one, name, entity_class, options)

        name = name.to_sym

        define_method(name) do
          identity = fk_identity(name)

          if identity
            session.lookup(entity_class, identity)
          else
            nil
          end
        end

        define_method("#{name}_id") do
          identity = fk_identity(name)

          if identity
            if identity > 0
              identity
            else
              nil # ephemeral entity
            end
          else
            nil
          end
        end
      end

      alias_method :one_to_one, :many_to_one

      def one_to_many(name, entity_class, options)
        ad = add_association_description(:one_to_many, name, entity_class, options)

        name = name.to_sym

        define_method(name) do
          changes = self.association_adjustments.select { |o| o.name == name }

          unchanged =
            if ephemeral?
              []
            else
              self.cache_association(name) {
                foreign_key =
                  if ad.inverse_of
                    ad.entity_class.association_definitions[ad.inverse_of].foreign_key
                  else
                    ad.foreign_key or raise InvalidStateError, "Missing foreign key for association '#{name}' in #{self.inspect}"
                  end
                self.repo.family[entity_class].send('find_all_by_attribute', foreign_key, self.id)
              }
            end

          AssociationsDSL.apply_changes(changes, unchanged)
        end
      end

      def many_to_many(name, entity_class, options)
        ad = add_association_description(:many_to_many, name, entity_class, options)

        name = name.to_sym

        define_method(name) do
          changes = self.association_adjustments.select { |o| o.name == name }
          last_set_with_index = changes.zip(0...changes.length).select { |(o, _)| o.action == :set }.last
          changes = changes[last_set_with_index.last..-1] if last_set_with_index

          if last_set_with_index
            unchanged = []
          else
            unchanged = self.cache_association(name) {
              # TODO this roundabout dance about getting association as in DB is ugly
              public_send(ad.through) # initiate query
              join_entities = cached_association(ad.through) # pull value as it is in DB without changes applied

              if join_entities
                join_entities.map { |link| link.association(ad.source) }.sort_by(&:id)
              else
                []
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

        association_definitions[name] = AssociationDefinition.new(name, type, entity_class, options)
      end

      def self.apply_changes(changes, initial)
        changes.inject(initial) { |last, change|
          case change.action
          when :add
            last + change.entities
          when :remove
            last - change.entities
          when :set
            change.entities
          else
            fail
          end
        }
      end
    end
  end
end
