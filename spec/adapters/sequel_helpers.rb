module SequelHelpers
  def execute_simple_string_query(query)
    record = adapter.send(:sequel)[query].first
    record.values.first if record
  end

  def load_test_value(id)
    execute_simple_string_query( "select #{test_attr.to_s} from #{entity_table} where id = #{id}")
  end
end
