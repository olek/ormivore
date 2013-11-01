module App
  class AddressStorageSequelAdapter
    include ORMivore::SequelAdapter

    self.table_name = 'addresses'
    self.default_converter_class = AddressSqlStorageConverter
  end
end
