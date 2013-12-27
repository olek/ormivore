module ORMivore
  module PreparedSequelAdapter
    include SequelAdapter

    def self.included(base)
      base.extend(ClassMethods)
    end

    def initialize(options = {})
      super(options)
      @template_helper = TemplateHelper.new
    end

    def create(attrs)
      id = template_helper.insert(
        key_for(:create),
        {id: nil}.merge(extend_with_defaults(converter.to_storage(attrs)))
      ) {
        sequel.from(table_name)
      }

      attrs.merge(id: id)
    rescue Sequel::DatabaseError => e
      raise StorageError.new(e)
    end

    def update_all(conditions, attrs)
      template_helper.update(
        key_for(:update_all, conditions),
        template_helper.apply_scope(converter.to_storage(attrs), :attr).merge(
          template_helper.apply_scope(conditions, :cond))
      ) {
          ds = sequel.from(table_name)
          value_conditions = extract_value_conditions(conditions)
          value_list_conditions = extract_value_list_conditions(conditions)
          ds = ds.where(value_conditions) unless value_conditions.empty?
          value_list_conditions.each do |cond|
            ds = ds.where(*cond)
          end
        [
          ds,
          template_helper.hash_to_params(converter.to_storage(attrs), :attr)
        ]
      }
    rescue ActiveRecord::ActiveRecordError => e
      raise StorageError.new(e)
    end

    def find(conditions, attributes_to_load, options = {})
      order = options.fetch(:order, {})
      limit = Integer(options[:limit]) if options[:limit]
      offset = Integer(options[:offset]) if options[:offset]

      raise StorageError, "Missing limit for offset #{offset}" if !limit && offset

      query = template_helper.select(
        key_for(:find, conditions, attributes_to_load, options),
        conditions) {
          query = sequel.
            from(table_name).
            select(*converter.attributes_list_to_storage(attributes_to_load)).
            where(conditions).
            limit(limit).
            offset(offset)

          query = query.order(*order_by_clause(order)) unless order.empty?

          query
        }

      query.map { |r| entity_attributes(r) }
    end

    private

    attr_reader :template_helper

    # TODO there may be a better way to generate prepared statement keys
    def key_for(operation, *params)
      fingerprint = params.inspect
      fingerprint = Digest::MD5.hexdigest(fingerprint)
      :"#{operation}_#{fingerprint}"
    end

    def extract_value_conditions(conditions)
      template_helper.hash_to_params(
        conditions.reject { |k, v| v.is_a?(Array) },
        :cond
      )
    end

    def extract_value_list_conditions(conditions)
      template_helper.hash_to_params(
        conditions.select { |k, v| v.is_a?(Array) },
        :cond
      ).map { |k, v|
        ["#{k} IN ?", v]
      }
    end

    class TemplateHelper
      def initialize
        @statement_templates = {}
      end

      def select(key, parameters={}, &block)
        common_wrapper(key, parameters, block,
          lambda { |data_source| data_source.send(:to_prepared_statement, :select) }
        )
      end

      def first(key, parameters={}, &block)
        common_wrapper(key, parameters, block,
          lambda { |data_source| data_source.send(:to_prepared_statement, :first) }
        )
      end

      def delete(key, parameters={}, &block)
        common_wrapper(key, parameters, block,
          lambda { |data_source| data_source.send(:to_prepared_statement, :delete) }
        )
      end

      def insert(key, parameters={}, &block)
        common_wrapper(key, parameters, block,
          lambda { |data_source|
            data_source.send(:to_prepared_statement, :insert, [hash_to_params(parameters)])
          }
        )
      end

      def update(key, parameters={}, &block)
        common_wrapper(
          key, parameters, block,
          lambda { |(data_source, update_bindings)|
            data_source.send(:to_prepared_statement, :update, [update_bindings])
          })
      end

      def apply_scope(h, scope)
        p = "#{scope}_"
        h.each_with_object({}) { |(k, v), memo| memo[:"#{p}#{k}"] = v }
      end

      def hash_to_params(h, scope = nil)
        p = scope ? "#{scope}_" : ''
        h.each_with_object({}) { |(k, v), memo|
          unless k == :sql_type
            memo[k] = "$#{p}#{k}".to_sym
          end
        }
      end

      private

      attr_reader :statement_templates

      def common_wrapper(key, parameters, ds_block, templetize_block)
        raise unless key
        raise unless key.is_a? Symbol

        template = statement_templates[key]

        unless template
          data_source = ds_block.call
          template = statement_templates[key] = templetize_block.call(data_source)
        end

        template.call(parameters)
      end
    end
  end
end
