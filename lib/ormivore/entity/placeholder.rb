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
    end
  end
end
