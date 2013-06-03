module App
  class AddressStoragePort
    # a good place to add generic storage functionality,
    # like 'around' logging/performance monitoring/notifications/etc
    # first obvious candidate is exception handling

    def initialize(adapter)
      @adapter = adapter
    end

    def find(conditions, options = {})
      # TODO verify conditions and options
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
  end
end
