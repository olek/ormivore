module App
  class AccountStorageArAdapter
    include ORMivore::ArAdapter
    self.default_converter_class = AccountSqlStorageConverter
    self.ignored_columns = %w(login crypted_password salt created_at updated_at)
    self.table_name = 'accounts'

    define_default_attributes do |attrs|
      {
        login: attrs[:email],
        crypted_password: 'Unknown'
      }
    end
  end
end

