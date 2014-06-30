module ORMivore
  module RepoDSL

    private

    # TODO extract common code from find/page
    # TODO rename 'named' arg to 'name'

    def find(type, options)
      raise BadArgumentError, "No finder type provided" unless type
      type = type.to_sym
      raise BadArgumentError, "Invalid finder type '#{type}'" unless [:first, :all].include?(type)
      raise BadArgumentError, "No finder options provided" unless options
      options = options.symbolize_keys
      raise BadArgumentError, "Limit option not allowed" if options[:limit] && type == :first

      keys = options.fetch(:by, nil)
      keys = [*keys].sort.map(&:to_sym)

      finder_name = options.fetch(:named, keys.empty? ? nil : "by_#{keys.join('_and_')}")

      filter_by = options.fetch(:filter_by, {})

      options.delete(:by)
      options.delete(:named)
      options.delete(:filter_by)
      options.merge!(limit: 1) if type == :first

      name = [(type == :first ? nil : type), finder_name].compact.join('_')

      define_method("find_#{name}") do |*args|
        port_options = options

        raise BadArgumentError, "Invalid number of arguments" unless args.length == keys.length
        conditions = Hash[keys.zip(args)]

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

    def page(options)
      raise BadArgumentError, "No finder options provided" unless options
      options = options.symbolize_keys
      raise BadArgumentError, "Limit option not allowed" if options[:limit] && type == :first

      keys = options.fetch(:by, nil)
      keys = [*keys].sort.map(&:to_sym)

      finder_name = options.fetch(:named, keys.empty? ? nil : "by_#{keys.join('_and_')}")

      filter_by = options.fetch(:filter_by, {})
      page_size = options.fetch(:page_size, 10)

      page_size = Integer(page_size) rescue raise(BadArgumentError, "Bad page_size argument #{page_size.inspect}")
      raise BadArgumentError, "Bad page_size argument #{page_size.inspect}" unless page_size > 0

      options.delete(:by)
      options.delete(:named)
      options.delete(:filter_by)
      options.delete(:page_size)
      options.delete(:limit)
      options.delete(:offset)

      name = finder_name

      define_method("page_#{name}") do |*args|
        port_options = options

        page = args.pop or raise BadArgumentError, 'No page argument provided'
        page = Integer(page) rescue raise(BadArgumentError, "Bad page argument #{page.inspect}")
        raise BadArgumentError, "Bad page argument #{page.inspect}" unless page > 0

        offset = (page - 1) * page_size

        port_options = port_options.merge(
          limit: page_size,
          offset: offset
        )

        raise BadArgumentError, "Invalid number of arguments" unless args.length == keys.length
        conditions = Hash[keys.zip(args)]

        entities_attrs = port.find(
          filter_by.merge(conditions),
          all_known_columns,
          port_options
        )
        entities = entities_attrs.map { |ea|
          load_entity(ea)
        }

        # TODO define port.count generic interface
        # count = port.count(filter_by.merge(conditions))
        # This way of determining count is silly, but will do for now
        all_entities_attrs = port.find(
          filter_by.merge(conditions),
          all_known_columns,
          options
        )
        count = all_entities_attrs.length
        total_pages = count / page_size + (count % page_size == 0 ? 0 : 1)

        [entities, total_pages]
      end
    end
  end
end
