require 'spec_helper'

require_relative 'shared_basic'
require_relative 'shared_expanded'
require_relative 'memory_helpers'
require_relative 'ar_helpers'
require_relative 'redis_helpers'

describe 'account storage adapters' do
  let(:attrs) do
    v = test_value
    { firstname: v, lastname: v, email: v, status: :active }
  end

  let(:test_attr) { :firstname }

  let(:factory_name) { :account }
  let(:factory_attrs) { {} }

  describe App::AccountStorageMemoryAdapter do
    it_behaves_like 'an expanded adapter' do
      include MemoryHelpers
      let(:adapter) { App::AccountStorageMemoryAdapter.new }
    end
  end

  describe App::AccountStorageArAdapter, :relational_db do
    it_behaves_like 'an expanded adapter' do
      include ArHelpers
      let(:entity_table) { 'accounts' }
      let(:adapter) { App::AccountStorageArAdapter.new }
    end
  end

  describe App::AccountStorageRedisAdapter, :redis_db do
    it_behaves_like 'a basic adapter' do
      include RedisHelpers
      let(:prefix) { 'accounts' }
      let(:adapter) { App::AccountStorageRedisAdapter.new }
    end
  end
end
