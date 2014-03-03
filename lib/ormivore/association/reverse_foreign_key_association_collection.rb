module ORMivore
  module Association
    class ReverseForeignKeyAssociationCollection
      def initialize(identity, association_definition, session)
        @identity = identity
        @name = association_definition.as
        @fk_name = association_definition.foreign_key_name
        @identity_map = session.identity_map(association_definition.from)
        @repo = session.repo(association_definition.from)
      end

      def values
        removals, additions = fk_identity_changes

        unchanged - removals + additions
      end

      def set(entities)
        remove(values)
        add(entities)
      end

      def add(entities)
        entities.map { |e|
          e.apply(fk_name => identity)
        }
      end

      def remove(entities)
        entities.map { |e|
          e.apply(fk_name => nil)
        }
      end

      private

      def unchanged
        if identity > 0
          repo.send('find_all_by_attribute', fk_name, identity)
        else
          []
        end
      end

      def fk_identity_changes
        removal, additions = [], []

        additions =
          identity_map.select { |o|
            o.changes[fk_name] == identity
          }

        if identity > 0
          removal =
              identity_map.select { |o|
                changes = o.changes
                changes.has_key?(fk_name) &&
                  changes[fk_name] != identity &&
                  o.durable_ancestor.attribute(fk_name) == identity
              }
        end

        [removal, additions]
      end

      attr_reader :identity, :name, :fk_name, :identity_map, :repo
    end
  end
end
