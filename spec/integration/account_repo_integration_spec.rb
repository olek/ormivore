require 'spec_helper'
require_relative 'shared'
require_relative '../adapters/memory_helpers'
require_relative '../adapters/ar_helpers'
require_relative '../adapters/sequel_helpers'
require_relative '../adapters/redis_helpers'

describe App::AccountRepo do
  let(:attrs) do
    v = test_value
    { firstname: v, lastname: v, email: v, status: :active }
  end

  let(:test_attr) { :firstname }
  let(:entity_class) { App::Account }
  let(:port) { App::AccountStoragePort.new(adapter) }

  let(:factory_name) { :account }
  let(:factory_attrs) { {} }

  context 'with AccountStorageMemoryAdapter' do
    include MemoryHelpers

    let(:adapter) { App::AccountStorageMemoryAdapter.new }

    it_behaves_like 'an integrated repo'
  end

  context 'with AccountStorageArAdapter', :relational_db do
    include ArHelpers

    let(:entity_table) { 'accounts' }
    let(:adapter) { App::AccountStorageArAdapter.new }

    it_behaves_like 'an integrated repo'
  end

  context 'with AccountStorageSequelAdapter', :relational_db do
    include SequelHelpers

    let(:entity_table) { 'accounts' }
    let(:adapter) { App::AccountStorageSequelAdapter.new }

    it_behaves_like 'an integrated repo'
  end

  context 'with AccountStoragePreparedSequelAdapter', :sequel_db do
    include SequelHelpers

    let(:entity_table) { 'accounts' }
    let(:adapter) { App::AccountStoragePreparedSequelAdapter.new }

    it_behaves_like 'an integrated repo'
  end

  context 'with AccountStorageRedisAdapter', :redis_db do
    include RedisHelpers

    let(:prefix) { 'accounts' }
    let(:adapter) { App::AccountStorageRedisAdapter.new }

    it_behaves_like 'an integrated repo'
  end
end
