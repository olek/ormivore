module App
  class AddressStoragePreparedSequelAdapter
    include ORMivore::PreparedSequelAdapter

    self.table_name = 'addresses'
    self.default_converter_class = AddressSqlStorageConverter
  end
end
