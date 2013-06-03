require 'spec_helper'
require_relative 'shared'

describe App::AddressRepo do

  let(:account_id) { FactoryGirl.create(:account).id }

  let(:attrs) do
    v = 'Foo'
    {
      street_1: v, city: v, postal_code: v,
      country_code: v, region_code: v,
      type: :shipping, account_id: account_id
    }
  end

  let(:test_attr) { :street_1 }
  let(:entity_table) { 'addresses' }
  let(:entity_class) { App::Address }

  subject {
    described_class.new(
      App::AddressStoragePort.new(
        App::AddressStorageArAdapter.new
      )
    )
  }

  def create_entity
    FactoryGirl.create(:shipping_address, test_attr => test_value, addressable_id: account_id)
  end

  it_behaves_like 'a repo'
end
