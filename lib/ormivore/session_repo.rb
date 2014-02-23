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

      identity_map # prime before freezing

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
          make_current = true
          results = memoize(name) do
            make_current = false
            repo.send(name, *args)
          end

          make_current ? make_current(results) : results
        end
      end
    end

    def singleton
      @singleton ||= (class << self; self; end)
    end

    def make_current(e)
      if e
        if e.is_a?(Array)
          e.map { |o|
            identity_map.current(o)
          }
        else
          identity_map.current(e)
        end
      else
        e
      end
    end

    def identity_map
      @identity_map ||= repo.session.identity_map(repo.entity_class)
    end
  end
end
