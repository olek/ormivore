require 'spec_helper'

require_relative 'shared_expanded'
require_relative 'memory_helpers'
require_relative 'ar_helpers'
require_relative 'sequel_helpers'
require_relative 'redis_helpers'

describe 'address storage adapters' do
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

  let(:factory_name) { :shipping_address }
  let(:factory_attrs) { { account_id: account_id } }

  describe App::AddressStorageMemoryAdapter do
    include MemoryHelpers

    let(:account_adapter) { App::AccountStorageMemoryAdapter.new }
    let(:adapter) { App::AddressStorageMemoryAdapter.new }

    it_behaves_like 'an expanded adapter'
  end

  describe App::AddressStorageArAdapter, :relational_db do
    include ArHelpers

    let(:account_adapter) { App::AccountStorageArAdapter.new }
    let(:entity_table) { 'addresses' }
    let(:adapter) { App::AddressStorageArAdapter.new }

    it_behaves_like 'an expanded adapter'
  end

  describe App::AddressStorageSequelAdapter, :relational_db do
    include SequelHelpers

    let(:account_adapter) { App::AccountStorageSequelAdapter.new }
    let(:entity_table) { 'addresses' }
    let(:adapter) { App::AddressStorageSequelAdapter.new }

    it_behaves_like 'an expanded adapter'
  end

  describe App::AddressStorageRedisAdapter, :redis_db do
    include RedisHelpers

    let(:account_adapter) { App::AccountStorageRedisAdapter.new }
    let(:prefix) { 'addresses' }
    let(:adapter) { App::AddressStorageRedisAdapter.new }

    it_behaves_like 'a basic adapter'
  end
end
