require 'spec_helper'
require_relative 'shared'

describe App::AddressStorageArAdapter do
  include Helpers

  let(:account_id) { FactoryGirl.create(:account).id }

  let(:attrs) do
    v = 'Foo'
    {
      street_1: v, city: v, postal_code: v,
      country_code: v, region_code: v,
      addressable_type: 'Account',
      addressable_id: account_id
    }
  end

  let(:test_attr) { :street_1 }
  let(:entity_table) { 'addresses' }

  def create_entity
    account = FactoryGirl.create(:account)
    FactoryGirl.create(:shipping_address, addressable_id: account.id, addressable_type: 'Account')
  end

  it_behaves_like 'an adapter'
end
