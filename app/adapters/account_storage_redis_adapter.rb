module App
  class AccountStorageRedisAdapter
    include ORMivore::RedisAdapter

    self.prefix = 'accounts'
    self.default_converter_class = NoopConverter
  end
end
