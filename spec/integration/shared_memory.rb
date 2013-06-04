require_relative 'shared'

shared_examples_for 'an integrated memory repo' do
  def create_entity
    adapter.create(attrs)
  end

  def load_test_value(id)
    adapter.storage.first { |o| o[:id] = id }[test_attr]
  end

  it_behaves_like 'an integrated repo'
end
