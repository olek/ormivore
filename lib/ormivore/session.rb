module ORMivore
  class Session
    NULL = Object.new.tap do |o|
      def repo(entity_class); 'This would have been repo'; end
      def o.to_s; "#{Module.nesting.first.name}::NULL"; end
      def o.register(entity); entity; end
      def o.identity_map(entity_class); IdentityMap::NULL end
      def o.generate_identity(*args); -3 end
    end

    def initialize(repo_family)
      fail unless repo_family

      @repo_family = Object.new.tap do |o|
        o.extend ORMivore::RepoFamily
        repo_family.keys.each do |ec|
          source_repo = repo_family[ec]
          source_repo.clone(family: o, session: self)
        end
      end

      @identity_maps =
        @repo_family.keys.each_with_object({}) do |ec, acc|
          acc[ec] = IdentityMap.new(ec)
        end

      @caching_repos =
        @repo_family.keys.each_with_object({}) do |ec, acc|
          acc[ec] = SessionRepo.new(@repo_family[ec])
        end

      @current_generated_identities = Hash.new(0)

      @repo_family.freeze
      @caching_repos.freeze
      @identity_maps.freeze

      freeze
    end

    def repo(entity_class)
      caching_repos[entity_class]
    end

    def register(entity)
      fail unless entity
      fail unless repo_family.keys.include?(entity.class)

      identity_maps[entity.class].set(entity)
    end

    def identity_map(entity_class)
      identity_maps[entity_class]
    end

    def generate_identity(entity_class)
      fail unless entity_class
      fail unless repo_family.keys.include?(entity_class)

      current_generated_identities[entity_class] -= 1
    end

    private

    attr_reader :repo_family, :identity_maps, :caching_repos
  end
end
