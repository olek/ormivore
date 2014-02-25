module ORMivore
  module Entity
    class Placeholder
      attr_reader :id

      def initialize(repo, id)
        @repo = repo or fail
        @id = id or fail
        freeze
      end

      def dereference_placeholder
        @repo.find_by_id(@id)
      end

      # pretending to be an entity
      def inspect(options = {})
        "#<#{self.class.name} id=#{id}>"
      end

      # customizing to_yaml output that otherwise is a bit too long
      def encode_with(encoder)
        encoder['id'] = @id
        encoder['repo'] = @repo.inspect
      end
    end
  end
end
