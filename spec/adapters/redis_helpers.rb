module RedisHelpers
  def load_test_value(id)
    adapter.send(:redis).hget("#{prefix}:#{id}", test_attr.to_s)
  end
end
