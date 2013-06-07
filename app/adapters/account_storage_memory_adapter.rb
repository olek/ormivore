module App
  class AccountStorageMemoryAdapter
    include ORMivore::MemoryAdapter
    self.default_converter_class = NoopConverter
  end
end
