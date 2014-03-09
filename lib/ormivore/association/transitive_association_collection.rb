module ORMivore
  module Association
    class TransitiveAssociationCollection
      def initialize(identity, association_definition, via_association_definition, session)
        @identity = identity
        @via = association_definition.via
        @via_nature = association_definition.via_nature
        @linked_by = association_definition.linked_by
        @identity_map = session.identity_map(association_definition.from)
        @session = session
        @via_class = via_association_definition.from
        @via_backlink = via_association_definition.as
        @via_identity_map = session.identity_map(@via_class)
      end

      def values
        via_association.values.map { |o|
          session.association(o, linked_by).value
        }.flatten.compact
      end

      def clear
        set
      end

      def set(*entities)
        remove(*values)
        add(*entities)
      end

      def add(*entities)
        entities -= values

        entities.map { |entity|
          session.repo(via_class).create(fk(via_backlink) => identity, fk(linked_by) => entity.identity)
        }
      end

      def remove(*entities)
        entities &= values # intersection, no duplicates
        entity_identities = entities.map(&:identity)

        via_association.values.map { |o|
          if entity_identities.include?(o.attribute(fk(linked_by)))
            if via_nature == :incidental
              via_identity_map.delete(o)
            else
              o.apply(fk(linked_by) => nil)
            end
          end
        }.compact
      end

      private

      def fk(name)
        :"#{name}_id"
      end

      def via_association
        session.association(identity_map[identity], via)
      end

      attr_reader :identity, :linked_by, :identity_map, :session
      attr_reader :via, :via_nature, :via_class, :via_backlink, :via_identity_map
    end
  end
end
