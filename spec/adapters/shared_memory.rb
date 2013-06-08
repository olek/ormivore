require_relative 'shared'

shared_examples_for 'a memory adapter' do
  def create_entity(overrides = {})
    subject.create(attrs.merge(overrides))
  end

  def load_test_value(id)
    subject.storage.first { |o| o[:id] = id }[test_attr]
  end

  it_behaves_like 'an adapter'
end
