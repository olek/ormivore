module ORMivore
  module Association
    class ReverseForeignKeyAssociationCoolection
      def initialize(identity, association_definition, session)
        @identity = identity
        @name = association_definition.as
        @identity_map = session.identity_map(association_definition.from)
        @repo = session.repo(association_definition.from)
      end

      def values
        removals, additions = fk_identity_changes

        unchanged =
          if identity > 0
            repo.send('find_all_by_attribute', fk_name, identity)
          else
            []
          end

        unchanged - removals + additions
      end

      private

      def fk_name
        "#{name}_id"
      end

      def fk_identity_changes
        removal, additions = [], []

        additions =
          identity_map.select { |o|
            o.fk_identity_changes[fk_name] == identity
          }

        if identity > 0
          removal =
              identity_map.select { |o|
                fk_identity_changes = o.fk_identity_changes
                fk_identity_changes.has_key?(fk_name) &&
                  fk_identity_changes[fk_name] != identity &&
                  o.durable_ancestor.fk_identity(fk_name) == identity
              }
        end

        [removal, additions]
      end

      attr_reader :identity, :name, :identity_map, :repo
    end
  end
end
