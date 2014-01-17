module MemoryHelpers
  def load_test_value(id)
    record = adapter.storage.first { |o| o[:id] = id }
    record[test_attr] if record
  end
end
