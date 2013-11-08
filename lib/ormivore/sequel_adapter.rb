module ORMivore
  module SequelAdapter
    include ConvenienceIdFinders

    module ClassMethods
      attr_reader :default_converter_class
      attr_reader :table_name

      private
      attr_writer :default_converter_class
      attr_writer :table_name

      def expand_on_create(&block)
        @expand_on_create = block
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    def initialize(options = {})
      @converter = options[:converter] || self.class.default_converter_class.new
      @sequel = (options[:sequel] || ORMivore::Connections.sequel) or fail "Sequel connection is not provided/available"
    end

    def find(conditions, attributes_to_load, options = {})
      order = options.fetch(:order, {})
      limit = Integer(options[:limit]) if options[:limit]
      offset = Integer(options[:offset]) if options[:offset]

      raise StorageError, "Missing limit for offset #{offset}" if !limit && offset

      query = sequel.
        from(table_name).
        select(*converter.attributes_list_to_storage(attributes_to_load)).
        where(conditions).
        limit(limit).
        offset(offset)

      query = query.order(*order_by_clause(order)) unless order.empty?

      # puts "DDDDD: query = #{query.sql}"

      query.map { |r| entity_attributes(r) }
    end

    def create(attrs)
      id = sequel.
        from(table_name).
          insert(
            extend_with_defaults(
              converter.to_storage(attrs))
          )

        attrs.merge(id: id)
    rescue Sequel::DatabaseError => e
      raise StorageError.new(e)
    end


    def update_one(id, attrs)
      update_all({ id: id }, attrs)
    end

    def update_all(conditions, attrs)
      sequel.
        from(table_name).
        where(conditions).
        update(converter.to_storage(attrs))
    rescue ActiveRecord::ActiveRecordError => e
      raise StorageError.new(e)
    end

    private

    attr_reader :converter, :sequel

    def extend_with_defaults(attrs)
      now = Time.now
      attrs = { created_at: now, updated_at: now }.merge(attrs)
      expansion = self.class.instance_variable_get(:@expand_on_create)
      if expansion
        attrs.merge(expansion.call(attrs))
      else
        attrs
      end
    end

    def order_by_clause(order)
      return '' if order.empty?

      order.map { |k, v|
        case v
        when :ascending
          k.to_sym
        when :descending
          Sequel.desc(k.to_sym)
        else
          raise BadArgumentError, "Order direction #{v} is invalid"
        end
      }
    end

    def table_name
      self.class.table_name
    end

    def entity_attributes(record)
      converter.from_storage(record.symbolize_keys)
    end
  end
end

