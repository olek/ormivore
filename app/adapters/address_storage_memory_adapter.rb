module App
  class AddressStorageMemoryAdapter
    include ORMivore::MemoryAdapter
    self.default_converter_class = NoopConverter
    self.entity_name = 'Address'
  end
end
