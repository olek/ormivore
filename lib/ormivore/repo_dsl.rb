module ORMivore
  module RepoDSL

    private

    def find(type, options)
      raise BadArgumentError, "No finder type provided" unless type
      type = type.to_sym
      raise BadArgumentError, "Invalid finder type '#{type}'" unless [:first, :all].include?(type)
      raise BadArgumentError, "No finder options provided" unless options
      options = options.symbolize_keys
      raise BadArgumentError, "Limit option not allowed" if options[:limit] && type == :first

      keys = options.fetch(:by, nil)
      keys = [*keys].sort.map(&:to_sym)

      finder_name = options.fetch(:named, "by_#{keys.join('_and_')}")

      options.delete(:by)
      options.delete(:named)
      options.merge!(limit: 1) if type == :first

      infix = type == :first ? '' : "#{type}_"

      define_method("find_#{infix}#{finder_name}") do |*args|
        raise BadArgumentError, "Invalid number of arguments" unless args.length == keys.length
        conditions = Hash[keys.zip(args)]

        entities_attrs = port.find(
          conditions,
          all_known_columns,
          options
        )
        entities = entities_attrs.map { |ea| load_entity(ea) }
        type == :first ? entities.first : entities
      end
    end
  end
end
