module ORMivore
  module Port
    module ClassMethods
      attr_reader :attributes

      private
      attr_writer :attributes
    end

    def self.included(base)
      base.extend(ClassMethods)
    end
    # a good place to add generic storage functionality,
    # like 'around' logging/performance monitoring/notifications/etc
    # first obvious candidate is exception handling

    def initialize(adapter)
      @adapter = adapter
    end

    def find_by_id(id, attributes_to_load)
      validate_finder_options({}, attributes_to_load)

      adapter.find_by_id(id, attributes_to_load)
    end

    def find_all_by_id(ids, attributes_to_load)
      validate_finder_options({}, attributes_to_load)

      adapter.find_all_by_id(ids, attributes_to_load)
    end

    def find(conditions, attributes_to_load, options = {})
      validate_finder_options(options, attributes_to_load)

      adapter.find(conditions, attributes_to_load, options)
    end

    def create(attrs)
      begin
        adapter.create(attrs)
      rescue => e
        raise ORMivore::StorageError, e.message
      end
    end

    def update_one(id, attrs)
      adapter.update_one(id, attrs)
    rescue => e
      raise ORMivore::StorageError, e.message
    end

    def update_all(conditions, attrs)
      adapter.update_all(conditions, attrs)
    rescue => e
      raise ORMivore::StorageError, e.message
    end

    def delete_one(id)
      adapter.delete_one(id)
    rescue => e
      raise ORMivore::StorageError, e.message
    end

    def delete_all(conditions)
      adapter.delete_all(conditions)
    rescue => e
      raise ORMivore::StorageError, e.message
    end

    private

    attr_reader :adapter

    def validate_finder_options(options, attributes_to_load)
      options = options.dup
      valid = true

      order = options.delete(:order) || {}
      limit = options.delete(:limit)
      offset = options.delete(:offset)
      valid = false unless options.empty?

      raise ORMivore::BadArgumentError, "Invalid finder options #{options.inspect}" unless valid

      validate_order(order, attributes_to_load)
      Integer(limit) if limit
      Integer(offset) if offset

      nil
    end

    def validate_order(order, attributes_to_load)
      # TODO matching agains attributes_to_load is not good, sometimes user wants to sort on non-loaded attribute
      return if order.empty?

      unless order.keys.all? { |k| attributes_to_load.include?(k) }
        raise BadArgumentError, "Invalid order key in #{order.inspect}"
      end
    end
  end
end
