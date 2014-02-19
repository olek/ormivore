module ORMivore
  module Entity
    class AssociationAdjustment
      attr_reader :name, :action, :entities

      def initialize(name, action, entities)
        @name = name or raise BadArgumentError
        @action = action or raise BadArgumentError
        @entities = entities or raise BadArgumentError

        freeze
      end

      def ==(other)
        return false unless other.class == self.class

        return name == other.name &&
          action == other.action &&
          entities.eql?(other.entities) # eql? because otherwise sequential changes to derived entity are thrown away
      end

      alias eql? ==

      def hash
        return name.hash ^
          action.hash ^
          entities.hash
      end
    end
  end
end
