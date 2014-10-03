module ORMivore
  module Association
    class ReverseForeignKeyAssociationCollection
      def initialize(identity, association_definition, session)
        @identity = identity
        @name = association_definition.as
        @fk_name = association_definition.foreign_key_name
        @obverse_identity_map = session.identity_map(association_definition.from)
        @reverse_identity_map = session.identity_map(association_definition.to)
        @repo = session.repo(association_definition.from)
      end

      def values
        renew_identity

        removals, additions = fk_identity_changes

        (unchanged - removals + additions).sort_by(&:identity)
      end

      def set(*entities)
        remove(*(values - entities))
        add(*entities)
      end

      def add(*entities)
        renew_identity

        entities.map { |e|
          e.apply(fk_name => identity)
        }
      end

      def remove(*entities)
        entities.map { |e|
          e.apply(fk_name => nil)
        }
      end

      private

      def renew_identity
        @identity = reverse_identity_map[identity].identity
      end

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
          obverse_identity_map.select { |o|
            o.changes[fk_name] == identity
          }.map(&:pointer)

        if identity > 0
          removal =
              obverse_identity_map.select { |o|
                changes = o.changes
                changes.has_key?(fk_name) &&
                  changes[fk_name] != identity &&
                  o.durable_ancestor.attribute(fk_name) == identity
              }.map(&:pointer)
        end

        [removal, additions]
      end

      attr_reader :identity, :name, :fk_name, :obverse_identity_map, :reverse_identity_map, :repo
    end
  end
end
