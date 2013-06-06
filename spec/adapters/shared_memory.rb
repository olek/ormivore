require_relative 'shared'

shared_examples_for 'a memory adapter' do
  def create_entity
    subject.create(attrs)
  end

  def load_test_value(id)
    subject.storage.first { |o| o[:id] = id }[test_attr]
  end

  it_behaves_like 'an adapter'
end
