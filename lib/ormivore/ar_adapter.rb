module ORMivore
  module ArAdapter
    include ConvenienceIdFinders

    module ClassMethods
      attr_reader :default_converter_class
      attr_reader :table_name

      def ar_class
        finalize
        self::ArRecord
      end

      private
      attr_writer :default_converter_class
      attr_writer :table_name

      def expand_on_create(&block)
        @expand_on_create = block
      end

      def finalize
        unless @finalized
          @finalized = true

          file, line = caller.first.split(':', 2)
          line = line.to_i

          module_eval(<<-EOS, file, line - 1)
            class ArRecord < ActiveRecord::Base
              self.table_name = '#{table_name}'
              self.inheritance_column = :_type_disabled
              # This is cool but works only when strong parameters are in use (rails 4 or rails 3 + gem)
              # include ActiveModel::ForbiddenAttributesProtection
              attr_protected :id
            end
          EOS
        end
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    def initialize(options = {})
      @converter = options[:converter] || self.class.default_converter_class.new
    end

    def find(conditions, attributes_to_load, options = {})
      order = options.fetch(:order, {})
      limit = Integer(options[:limit]) if options[:limit]
      offset = Integer(options[:offset]) if options[:offset]

      ActiveRecord::Base.connection.select_all(
        ar_class.
          select(converter.attributes_list_to_storage(attributes_to_load)).
          where(conditions).
          order(order_by_clause(order)).
          limit(limit).
          offset(offset)
      ).map { |r| entity_attributes(r) }
    end

    def create(attrs)
      record = ar_class.create!(
        extend_with_defaults(
          converter.to_storage(attrs))) { |o| o.id = attrs[:id] }
       attrs.merge(id: record.id)
    rescue ActiveRecord::ActiveRecordError => e
      raise StorageError.new(e)
    end


    def update_one(id, attrs)
      update_all({ id: id }, attrs)
    end

    def update_all(conditions, attrs)
      ar_class.update_all(converter.to_storage(attrs), conditions)
    rescue ActiveRecord::ActiveRecordError => e
      raise StorageError.new(e)
    end

    private

    attr_reader :converter

    def extend_with_defaults(attrs)
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
        direction =
          case v
          when :ascending
            'asc'
          when :descending
            'desc'
          else
            raise BadArgumentError, "Order direction #{v} is invalid"
          end

        "#{k} #{direction}"
      }.join(', ')
    end

    def ar_class
      self.class.ar_class
    end

    def entity_attributes(record)
      converter.from_storage(record.symbolize_keys)
    end
  end
end
