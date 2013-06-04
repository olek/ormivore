require 'spec_helper'
require_relative 'shared_ar'

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
  let(:adapter) { App::AddressStorageArAdapter.new }
  let(:port) { App::AddressStoragePort.new(adapter) }

  def create_entity
    FactoryGirl.create(:shipping_address, test_attr => test_value, addressable_id: account_id).attributes.symbolize_keys
  end

  it_behaves_like 'an integrated activerecord repo'
end
