module App
  class AddressStorageRedisAdapter
    include ORMivore::RedisAdapter

    self.prefix = 'addresses'
    self.default_converter_class = NoopConverter
  end
end
