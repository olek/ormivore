module ORMivore
  module Entity
    class AssociationDefinition
      DIRECT_FOREIGN_KEY_TYPES = %w(one_to_one many_to_one).map(&:to_sym).freeze
      REVERSE_FOREIGN_KEY_TYPES = %w(one_to_many many_to_many).map(&:to_sym).freeze
      TYPES = (DIRECT_FOREIGN_KEY_TYPES + REVERSE_FOREIGN_KEY_TYPES).freeze

      attr_reader :name, :type, :entity_class
      attr_reader :through, :source
      attr_reader :foreign_key, :inverse_of

      def initialize(name, type, entity_class, options)
        @name = name or raise BadArgumentError
        @type = type or raise BadArgumentError
        @entity_class = entity_class or raise BadArgumentError

        @through = options[:through]
        @source = options[:source]

        @foreign_key = options[:fk]
        @inverse_of = options[:inverse_of]

        symbolize
        validate
      end

      def direct?
        DIRECT_FOREIGN_KEY_TYPES.include?(type)
      end

      def reverse?
        REVERSE_FOREIGN_KEY_TYPES.include?(type)
      end

      private

      def symbolize
        @name = name.to_sym if name
        @type = type.to_sym if type
        @through = through.to_sym if through
        @source = source.to_sym if source
        @foreign_key = foreign_key.to_sym if foreign_key
        @inverse_of = inverse_of.to_sym if inverse_of
      end

      # TODO expand this validation to cover many, many more cases...
      def validate
        raise BadArgumentError, "Unknown association type '#{type}'" unless TYPES.include?(type)

        if type == :many_to_many
          raise BadArgumentError, "No 'through' association defined on association '#{name}'" unless through
          raise BadArgumentError, "No 'source' association defined on association '#{name}'" unless source
        end
      end
    end
  end
end
