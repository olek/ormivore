module ORMivore
  class SessionRepo
    def initialize(repo)
      include_memoize_on_singleton

      @repo = repo or fail

      (%w(find_by_id find_all_by_id find_all_by_id_as_hash) +
        repo.public_methods(false).select { |m| m =~ /^find_/ }
      ).each do |m|
        define_finder_proxy(m)
      end

      freeze
    end

    private

    attr_reader :repo

    def include_memoize_on_singleton
      singleton.class_eval do
        include Entity::Memoize
      end
    end

    def define_finder_proxy(name)
      singleton.class_eval do
        define_method name do |*args|
          pass_through_identity_map(
            memoize(name) do
              repo.send(name, *args)
            end
          )
        end
      end
    end

    def singleton
      (class << self; self; end)
    end

    def pass_through_identity_map(e)
      if e
        if e.is_a?(Array)
          e.map { |o|
            identity_map.current_or_set(o)
          }
        else
          identity_map.current_or_set(e)
        end
      else
        e
      end
    end

    def identity_map
      repo.session.identity_map(repo.entity_class)
    end
  end
end
