require_relative 'shared'

shared_examples_for 'an integrated address repo' do
  let(:account_id) { FactoryGirl.create(:account, adapter: account_adapter).id }

  let(:attrs) do
    v = test_value
    {
      street_1: v, city: v, postal_code: v,
      country_code: v, region_code: v,
      type: :shipping, account_id: account_id
    }
  end

  let(:test_attr) { :street_1 }
  let(:entity_class) { App::Address }
  let(:port) { App::AddressStoragePort.new(adapter) }

  let(:factory_name) { :shipping_address }
  let(:factory_attrs) { { account_id: account_id } }

  it_behaves_like 'an integrated repo'
end
