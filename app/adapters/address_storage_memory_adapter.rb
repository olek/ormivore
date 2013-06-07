module App
  class AddressStorageMemoryAdapter
    include ORMivore::MemoryAdapter
    self.default_converter_class = NoopConverter
  end
end
