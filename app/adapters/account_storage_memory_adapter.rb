module App
  class AccountStorageMemoryAdapter
    include ORMivore::MemoryAdapter
    self.default_converter_class = NoopConverter
    self.entity_name = 'Account'
  end
end
