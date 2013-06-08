module App
  class AddressStorageArAdapter
    include ORMivore::ArAdapter

    self.table_name = 'addresses'
    self.default_converter_class = AddressSqlStorageConverter
  end
end
