module MemoryHelpers
  def load_test_value(id)
    adapter.storage.first { |o| o[:id] = id }[test_attr]
  end
end
