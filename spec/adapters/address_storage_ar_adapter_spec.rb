require 'spec_helper'
require_relative 'shared_ar'

describe App::AddressStorageArAdapter do
  let(:account_id) { FactoryGirl.create(:account).id }

  let(:attrs) do
    v = test_value
    {
      street_1: v, city: v, postal_code: v,
      country_code: v, region_code: v,
      addressable_type: 'Account',
      addressable_id: account_id
    }
  end

  let(:test_attr) { :street_1 }
  let(:entity_table) { 'addresses' }

  def create_entity(overrides = {})
    FactoryGirl.create(
      :shipping_address,
      { addressable_id: account_id, addressable_type: 'Account' }.merge(overrides)
    ).attributes.symbolize_keys
  end

  it_behaves_like 'an activerecord adapter'
end
