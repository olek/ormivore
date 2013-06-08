require_relative 'shared'

shared_examples_for 'an account adapter' do
  let(:attrs) do
    v = test_value
    { firstname: v, lastname: v, email: v, status: :active }
  end

  let(:test_attr) { :firstname }

  let(:factory_name) { :account }
  let(:factory_attrs) { {} }

  it_behaves_like 'an adapter'
end
