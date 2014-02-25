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

      @entity_classes = repo_family.keys

      @repo_family = Object.new.tap do |o|
        o.extend ORMivore::RepoFamily
      end

      @cloned_repos =
        entity_classes.each_with_object({}) do |ec, acc|
          source_repo = repo_family[ec]
          # those repos should use other SessionRepos to load associations
          acc[ec] = source_repo.clone(family: @repo_family, family_member: false, session: self)
        end

      @identity_maps =
        entity_classes.each_with_object({}) do |ec, acc|
          acc[ec] = IdentityMap.new(ec)
        end

      entity_classes.each do |ec|
        SessionRepo.new(@cloned_repos[ec], family: @repo_family)
      end

      @repos = Object.new.tap do |o|
        def o.to_s; "#{Module.nesting.first.name}::Repos"; end

        @repo_family.keys.each do |entity_class|
          name = entity_class.shorthand_notation
          next unless name
          repo = @repo_family[entity_class]

          o.define_singleton_method(name) {
            repo
          }
        end
      end

      @current_generated_identities = Hash.new(0)

      @cloned_repos.freeze
      @repo_family.freeze
      @identity_maps.freeze

      freeze
    end

    def repo(o = nil)
      if o
        if o.is_a?(Symbol)
          @repos.public_send(o)
        elsif o.include?(ORMivore::Entity)
          repo_family[o]
        else
          raise BadArgumentError, "Unexpected argument #{o.inspect}"
        end
      else
        @repos
      end
    end

    def register(entity)
      fail unless entity
      fail unless entity_classes.include?(entity.class)

      identity_maps[entity.class].set(entity)
    end

    def current(entity)
      fail unless entity
      fail unless entity_classes.include?(entity.class)

      identity_maps[entity.class].current(entity)
    end

    def identity_map(entity_class)
      identity_maps[entity_class]
    end

    def generate_identity(entity_class)
      fail unless entity_class
      fail unless entity_classes.include?(entity_class)

      current_generated_identities[entity_class] -= 1
    end

    def inspect(options = {})
      verbose = options.fetch(:verbose, false)

      "#<#{self.class.name}".tap { |s|
          if verbose
            s << " repo_family=#{repo_family.inspect}"
            s << " identity_maps=#{identity_maps.inspect}"
          else
            s << (":0x%08x" % (object_id * 2))
          end
      } << '>'
    end

    # customizing to_yaml output
    def encode_with(encoder)
      encoder['repo_family'] = repo_family
      encoder['identity_maps'] = identity_maps
    end

    private

    attr_reader :repo_family, :identity_maps, :entity_classes
  end
end
