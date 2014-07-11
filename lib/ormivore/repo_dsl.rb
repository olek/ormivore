module ORMivore
  module RepoDSL

    private

    # TODO rename 'named' arg to 'name'

    def find(type, options)
      raise BadArgumentError, "No finder type provided" unless type
      type = type.to_sym
      raise BadArgumentError, "Invalid finder type '#{type}'" unless [:first, :all].include?(type)
      raise BadArgumentError, "No finder options provided" unless options
      options = options.symbolize_keys
      raise BadArgumentError, "Limit option not allowed" if options[:limit] && type == :first

      suffix, finder_keys = finder_suffix_and_keys(options.delete(:named), options.delete(:by))

      filter_by = options.delete(:filter_by) || {}

      options.merge!(limit: 1) if type == :first

      suffix = [(type == :first ? nil : type), suffix].compact.join('_')
      raise BadArgumentError, "No 'named' or 'by' option provided for 'first' finder" unless suffix

      define_method("find_#{suffix}") do |*args|
        port_options = options

        raise BadArgumentError, "Invalid number of arguments" unless args.length == finder_keys.length
        conditions = Hash[finder_keys.zip(args)]

        entities_attrs = port.find(
          filter_by.merge(conditions),
          all_known_columns,
          port_options
        )
        entities = entities_attrs.map { |ea|
          load_entity(ea)
        }

        type == :first ? entities.first : entities
      end
    end

    def paginate(name, options = {})
      name, options = [nil, name] if options.empty? && name.respond_to?(:fetch)

      raise BadArgumentError, "No pagination options provided" unless options
      options = options.symbolize_keys
      raise BadArgumentError, "Limit option not allowed" if options[:limit] && type == :first

      suffix, finder_keys = finder_suffix_and_keys(name, options.delete(:by))
      raise BadArgumentError, "No name or 'by' option provided" unless suffix

      filter_by = options.delete(:filter_by) || {}
      page_size = options.delete(:page_size) || 10

      page_size = Integer(page_size) rescue raise(BadArgumentError, "Bad page_size argument #{page_size.inspect}")
      raise BadArgumentError, "Bad page_size argument #{page_size.inspect}" unless page_size > 0

      options.delete(:limit)
      options.delete(:offset)

      define_method("paginate_#{suffix}") do |*args|
        port_options = options

        page = args.pop or raise BadArgumentError, 'No page argument provided'
        page = Integer(page) rescue raise(BadArgumentError, "Bad page argument #{page.inspect}")
        raise BadArgumentError, "Bad page argument #{page.inspect}" unless page > 0

        offset = (page - 1) * page_size

        port_options = port_options.merge(
          limit: page_size,
          offset: offset
        )

        raise BadArgumentError, "Invalid number of arguments" unless args.length == finder_keys.length
        conditions = Hash[finder_keys.zip(args)]

        entities_attrs = port.find(
          filter_by.merge(conditions),
          all_known_columns,
          port_options
        )
        entities = entities_attrs.map { |ea|
          load_entity(ea)
        }

        count = port.count(filter_by.merge(conditions))
        total_pages = count / page_size + (count % page_size == 0 ? 0 : 1)

        [entities, total_pages]
      end
    end

    private

    def finder_suffix_and_keys(name, keys)
      keys = [*keys].sort.map(&:to_sym)

      [name || ("by_#{keys.join('_and_')}" unless keys.empty?), keys]
    end
  end
end
