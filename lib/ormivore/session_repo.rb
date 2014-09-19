module ORMivore
  class SessionRepo
    def initialize(repo, options)
      @singleton = (class << self; self; end)

      include_memoize_on_singleton

      @repo = repo or fail
      @family = options.fetch(:family)

      %w(create persist delete entity_class).each do |m|
        define_proxy(m)
      end

      # TODO need better strategy for proxying methods in SomeRepo by SessionRepo
      # matching methods by 'count_' prefix is not reliable
      (%w(find_by_id find_all_by_id find_all_by_id_as_hash find_all_by_attribute) +
        repo.public_methods(false).select { |m| m =~ /^find_/ } +
        repo.public_methods(false).select { |m| m =~ /^count_/ } +
        repo.public_methods(false).select { |m| m =~ /^paginate_/ }
      ).each do |m|
        define_memoized_proxy(m)
      end

      @family.add(self, repo.entity_class)

      freeze
    end

    def inspect(options = {})
      verbose = options.fetch(:verbose, false)

      "#<#{self.class.name}".tap { |s|
          if verbose
            s << " repo=#{repo.inspect(verbose: false)}"
          else
            s << (":0x%08x" % (object_id * 2))
          end
      } << '>'
    end

    # customizing to_yaml output
    def encode_with(encoder)
      encoder['repo'] = repo
    end

    attr_reader :family

    private

    attr_reader :repo, :singleton

    def include_memoize_on_singleton
      singleton.class_eval do
        include Memoize
      end
    end

    def define_proxy(name)
      singleton.class_eval do
        define_method name do |*args|
          repo.send(name, *args)
        end
      end
    end

    def define_memoized_proxy(name)
      singleton.class_eval do
        define_method name do |*args|
          mkey = "#{name}(#{args.inspect})"
          results = memoize(mkey) do
            repo.send(name, *args)
          end

          make_current(results)
        end
      end
    end

    def make_current(e)
      if e
        if e.is_a?(Array)
          e.map { |o|
            o.is_a?(ORMivore::Entity) ? o.current : o
          }.compact
        elsif e.is_a?(Hash)
          e.each_with_object({}) { |(k, v), acc|
            k = k.current if k.is_a?(ORMivore::Entity)
            v = v.current if v.is_a?(ORMivore::Entity)
            acc[k] = v
          }
        else
          e.is_a?(ORMivore::Entity) ? e.current : e
        end
      else
        nil
      end
    end
  end
end
