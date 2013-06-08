# TODO maybe add validations for conditions, if not attributes
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

    def find(conditions, attributes_to_load, options = {})
      # TODO verify conditions to contain only keys that match attribute names and value of proper type
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

    def update(attrs, conditions)
      adapter.update(attrs, conditions)
    rescue => e
      raise ORMivore::StorageError, e.message
    end

    private

    attr_reader :adapter

=begin
    def attributes
      self.class.attributes
    end

    def validate_conditions(conditions)
      extra = conditions.keys - attributes.keys
      raise BadConditionsError, extra.join("\n") unless extra.empty?
    end
=end

    def validate_finder_options(options, attributes_to_load)
      options = options.dup
      valid = true

      # TODO how about other finder options, like limit and offset?
      order = options.delete(:order) || {}
      valid = false unless options.empty?

      raise ORMivore::BadArgumentError, "Invalid finder options #{options.inspect}" unless valid

      validate_order(order, attributes_to_load)

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
