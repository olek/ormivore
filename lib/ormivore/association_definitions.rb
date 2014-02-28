module ORMivore
  module AssociationDefinitions
    NULL = Object.new.tap do |o|
      def o.to_s; "#{Module.nesting.first.name}::NULL"; end
      def o.fk_names_for(entity_class); [] end
    end

    module DSL
      def association(&block)
        fail unless block_given?
        association_definition_builder = AssociationDefinitionBuilder.new
        association_definition_builder.instance_eval(&block)

        association_definitions << association_definition_builder.call
      end

      class AssociationDefinitionBuilder
        attr_reader :foo

        def initialize
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

        def inverse_of(multiplier, name)
          fail unless multiplier
          fail unless name
          @inverse_of = [multiplier, name]
        end

        def call
          AssociationDefinition.new(@from, @to, @as, @inverse_of)
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

    private

    def association_definitions
      @association_definitions ||= []
    end
  end
end
