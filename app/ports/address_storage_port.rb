module ORMivoreApp
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
        raise StorageError, e.message
      end
    end

    def update(attrs, conditions)
      count = 0
      begin
        count = adapter.update_all(attrs, conditions)
      rescue => e
        raise StorageError, e.message
      end

      raise ORMivore::StorageError, 'No records updated' if count.zero?
      raise ORMivore::StorageError, 'WTF' if count > 1
    end

    private

    attr_reader :adapter
  end
end
