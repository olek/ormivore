module ORMivore
  class Session
    NULL = Object.new.tap do |o|
      def o.to_s; "#{Module.nesting.first.name}::NULL"; end
      def o.repo(entity_class = nil); 'This would have been repo'; end
      def o.register(entity); entity; end
      def o.current(entity); entity; end
      def o.lookup(entity_class, identity); nil; end
      def o.identity_map(entity_class); IdentityMap::NULL end
      def o.generate_identity(*args); -3 end
      def o.association_definitions; Association::AssociationDefinitions::NULL end
    end

    # 'public' API starts here

    def initialize(repo_family, association_definitions)
      fail unless repo_family
      fail unless association_definitions

      @association_definitions = association_definitions

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
        elsif o.include?(ORMivore::Pointer)
          repo_family[o.dereference]
        else
          raise BadArgumentError, "Unexpected argument #{o.inspect}"
        end
      else
        @repos
      end
    end

    # NOTE it worked well for ephemeral entities, not so much for
    # persisted entities
    #
    #def discard(entity)
    #  fail unless entity
    #  fail unless entity_classes.include?(entity.class)

    #  identity_maps[entity.class].unset(entity).try(:dismiss)
    #end

    def delete(pointer)
      fail unless pointer

      entity = pointer.dereference

      fail unless entity_classes.include?(entity.class)

      delete_associated_incidental_entities(entity)

      identity_maps[entity.class].delete(entity)

      pointer
    end

    def association(pointer, name)
      fail unless pointer
      fail unless name

      entity = pointer.dereference

      fail unless entity_classes.include?(entity.class)

      association_definitions.create_association(entity, name)
    end

    def commit
      SillySessionPersistenceStrategy.new(self).call
    end

    # TODO take care of duplication
    def commit_and_reset
      commit

      @repo_family.keys.each do |entity_class|
        repo = @repo_family[entity_class]
        repo.clear_memoizations
      end

      @identity_maps.values.each do |identity_map|
        identity_map.each do |entity|
          identity_map.unset(entity)
        end
      end
    end

    def reject_and_reset
      @repo_family.keys.each do |entity_class|
        repo = @repo_family[entity_class]
        repo.clear_memoizations
      end

      @identity_maps.values.each do |identity_map|
        identity_map.each do |entity|
          identity_map.unset(entity)
        end
      end
    end

    def reset
      @identity_maps.values.each do |identity_map|
        raise ORMivore::StorageError, "Can not reset session with changes" if identity_map.has_changes?
      end

      @repo_family.keys.each do |entity_class|
        repo = @repo_family[entity_class]
        repo.clear_memoizations
      end

      @identity_maps.values.each do |identity_map|
        identity_map.each do |entity|
          identity_map.unset(entity)
        end
      end
    end

    # 'public' API ends here

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

    # 'private' API begins here

    # 'private'
    def register(entity)
      fail unless entity

      fail unless entity_classes.include?(entity.class)

      identity_maps[entity.class].set(entity)
    end

    # 'private'
    def entity_classes
      identity_maps.keys
    end

    # 'private'
    def update_all_references_to(entity, new_identity)
      fail unless entity
      fail unless new_identity

      fail unless entity_classes.include?(entity.class)

      session.association_definitions.select { |o|
        o.type == :foreign_key &&
        o.to == entity.class
      }.each do |association_definition|
        session.identity_map(association_definition.from).select { |o|
          o.attribute(association_definition.foreign_key_name) == entity.identity
        }.each do |o|
          o.apply(association_definition.foreign_key_name => new_identity)
        end
      end
    end

    # 'private'
    def current(entity)
      fail unless entity
      fail unless entity_classes.include?(entity.class)

      im = identity_maps[entity.class]
      im.current(entity) || repo(entity.class).find_by_id(im.current_identity(entity)).dereference
    end

    # 'private'
    def lookup(entity_class, identity)
      fail unless entity_class
      fail unless identity

      unless entity_classes.include?(entity_class)
        fail "Expected entity class to be one of #{entity_classes}, got #{entity_class}"
      end

      identity_maps[entity_class][identity]
    end

    # 'private'
    def identity_map(entity_class)
      identity_maps[entity_class]
    end

    # 'private'
    def generate_identity(entity_class)
      fail unless entity_class
      fail unless entity_classes.include?(entity_class)

      current_generated_identities[entity_class] -= 1
    end

    attr_reader :association_definitions, :entity_classes

    # 'private' API ends here

    private

    attr_reader :repo_family, :identity_maps, :current_generated_identities

    def delete_associated_incidental_entities(entity)
      options = { reverse: true }

      association_definitions.select { |o|
        o.type == :transient &&
        o.from == entity.class &&
        o.via_nature == :incidental
      }.each do |association_definition|
        association_definition.via_association_definition.
          create_association(entity.identity, self, options).values.each do |o|
            self.delete(o)
          end
      end
    end
  end
end
