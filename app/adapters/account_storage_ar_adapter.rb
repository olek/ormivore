module App
  class AccountStorageArAdapter
    include ORMivore::ArAdapter
    self.default_converter_class = AccountSqlStorageConverter
    self.table_name = 'accounts'
    self.ignored_columns = %w(login crypted_password salt created_at updated_at)

    define_default_attributes do |attrs|
      {
        login: attrs[:email],
        crypted_password: 'Unknown'
      }
    end
  end
end

