require_relative 'shared'

shared_examples_for 'an integrated account repo' do
  let(:attrs) do
    v = test_value
    { firstname: v, lastname: v, email: v, status: :active }
  end

  let(:test_attr) { :firstname }
  let(:entity_class) { App::Account }
  let(:port) { App::AccountStoragePort.new(adapter) }

  let(:factory_name) { :account }
  let(:factory_attrs) { {} }

  it_behaves_like 'an integrated repo'
end
