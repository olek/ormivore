module ORMivore
  class SessionRepo
    def initialize(repo, options)
      @singleton = (class << self; self; end)

      include_memoize_on_singleton

      @repo = repo or fail
      @family = options.fetch(:family)

      %w(create persist delete).each do |m|
        define_proxy(m)
      end

      (%w(find_by_id find_all_by_id find_all_by_id_as_hash find_all_by_attribute) +
        repo.public_methods(false).select { |m| m =~ /^find_/ } +
        repo.public_methods(false).select { |m| m =~ /^paginate_/ }
      ).each do |m|
        define_finder_proxy(m)
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

    def define_finder_proxy(name)
      singleton.class_eval do
        define_method name do |*args|
          make_current = true
          mkey = "#{name}(#{args.inspect})"
          results = memoize(mkey) do
            make_current = false
            repo.send(name, *args)
          end

          make_current ? make_current(results) : results
        end
      end
    end

    def make_current(e)
      if e
        if e.is_a?(Array)
          e.map { |o|
            o.current
          }.compact
        else
          e.current
        end
      else
        nil
      end
    end
  end
end
