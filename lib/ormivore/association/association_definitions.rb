module ORMivore
  module Association
    module AssociationDefinitions
      NULL = Object.new.tap do |o|
        def o.to_s; "#{Module.nesting.first.name}::NULL"; end
        def o.fk_names_for(entity_class); [] end
        def o.select; [] end
      end

      module DSL
        def association(&block)
          fail unless block_given?
          association_definition_builder = AssociationDefinitionBuilder.new
          association_definition_builder.instance_eval(&block)

          association_definitions << association_definition_builder.call
        end

        def transitive_association(&block)
          fail unless block_given?
          association_definition_builder = TransitiveAssociationDefinitionBuilder.new(self)
          association_definition_builder.instance_eval(&block)

          association_definitions << association_definition_builder.call
        end

        class AssociationDefinitionBuilder
          def from(entity_class)
            @from = entity_class or fail
          end

          def to(entity_class)
            @to = entity_class or fail
          end

          def as(name)
            @as = name or fail
          end

          def reverse_as(multiplier, name)
            fail unless multiplier
            fail unless name
            @reverse_as = [multiplier, name]
          end

          def call
            AssociationDefinition.new(@from, @to, @as, @reverse_as)
          end
        end

        class TransitiveAssociationDefinitionBuilder
          def initialize(association_definitions)
            @association_definitions = association_definitions
          end

          def from(entity_class)
            @from = entity_class or fail
          end

          def to(entity_class)
            @to = entity_class or fail
          end

          def as(name)
            @as = name or fail
          end

          def via(via_nature, via)
            fail unless via_nature
            fail unless via
            @via = [via_nature, via] or fail
          end

          def linked_by(linked_by)
            @linked_by = linked_by or fail
          end

          def call
            TransientAssociationDefinition.new(@from, @to, @as, @via, @linked_by, @association_definitions)
          end
        end
      end

      module ClassMethods
      end

      def self.extended(base)
        base.extend(DSL)
        base.extend(Enumerable)
      end

      def each
        @association_definitions.each do |o|
          yield(o)
        end
      end

      def fk_names_for(entity_class)
        select { |o| o.from == entity_class }.map(&:as)
      end

      def create_association(entity, name)
        fail unless entity
        fail unless name

        raise StorageError, "Entity #{entity} dismissed." if entity.dismissed?

        name = name.to_sym

        ad = detect { |o| o.matches?(entity.class, name) || o.matches_in_reverse?(entity.class, name) }

        raise BadAttributesError, "Could not find association '#{name}' on entity #{entity.inspect}" unless ad

        options = {
          association_definitions: self,
          reverse: ad.matches_in_reverse?(entity.class, name)
        }

        ad.create_association(entity.identity, entity.session, options)
      end

      private

      def association_definitions
        @association_definitions ||= []
      end
    end
  end
end
