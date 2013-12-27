require 'spec_helper'
require_relative 'shared'
require_relative '../adapters/memory_helpers'
require_relative '../adapters/ar_helpers'
require_relative '../adapters/sequel_helpers'
require_relative '../adapters/redis_helpers'

describe App::AddressRepo do
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

  context 'with AddressStorageMemoryAdapter' do
    include MemoryHelpers

    let(:account_adapter) { App::AccountStorageMemoryAdapter.new }
    let(:adapter) { App::AddressStorageMemoryAdapter.new }

    it_behaves_like 'an integrated repo'
  end

  context 'with AddressStorageArAdapter', :ar_db do
    include ArHelpers

    let(:account_adapter) { App::AccountStorageArAdapter.new }
    let(:adapter) { App::AddressStorageArAdapter.new }
    let(:entity_table) { 'addresses' }

    it_behaves_like 'an integrated repo'
  end

  context 'with AddressStorageSequelAdapter', :sequel_db do
    include SequelHelpers

    let(:account_adapter) { App::AccountStorageSequelAdapter.new }
    let(:adapter) { App::AddressStorageSequelAdapter.new }
    let(:entity_table) { 'addresses' }

    it_behaves_like 'an integrated repo'
  end

  context 'with AddressStoragePreparedSequelAdapter', :sequel_db do
    include SequelHelpers

    let(:account_adapter) { App::AccountStoragePreparedSequelAdapter.new }
    let(:adapter) { App::AddressStoragePreparedSequelAdapter.new }
    let(:entity_table) { 'addresses' }

    it_behaves_like 'an integrated repo'
  end

  context 'with AddressStorageRedisAdapter', :redis_db do
    include RedisHelpers

    let(:account_adapter) { App::AccountStorageRedisAdapter.new }
    let(:adapter) { App::AddressStorageRedisAdapter.new }
    let(:prefix) { 'addresses' }

    it_behaves_like 'an integrated repo'
  end
end
