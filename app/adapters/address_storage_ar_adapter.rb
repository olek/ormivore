module App
  class AddressStorageArAdapter
    include ORMivore::ArAdapter
    self.default_converter_class = AddressSqlStorageConverter
    self.ignored_columns = %w(created_at updated_at)
    self.table_name = 'addresses'
  end
end
