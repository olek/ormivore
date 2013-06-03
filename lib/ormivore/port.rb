module ORMivore
  module Port
    # a good place to add generic storage functionality,
    # like 'around' logging/performance monitoring/notifications/etc
    # first obvious candidate is exception handling

    def initialize(adapter)
      @adapter = adapter
    end

    def find(conditions, options = {})
      # TODO verify conditions to contain only keys that match attribute names and value of proper type
      validate_finder_options(options)
      adapter.find(conditions, options)
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

    def validate_finder_options(options)
      options = options.dup
      valid = true

      valid = false unless [nil, true, false].include?(options.delete(:quiet))
      valid = false unless options.empty?

      raise ORMivore::BadArgumentError, "Invalid finder options #{options.inspect}" unless valid

      nil
    end
  end
end
