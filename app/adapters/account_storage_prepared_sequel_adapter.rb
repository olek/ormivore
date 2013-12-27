module App
  class AccountStoragePreparedSequelAdapter
    include ORMivore::PreparedSequelAdapter

    self.table_name = 'accounts'
    self.default_converter_class = AccountSqlStorageConverter

    expand_on_create do |attrs|
      {
        login: attrs[:email],
        crypted_password: 'Unknown'
      }
    end
  end
end
