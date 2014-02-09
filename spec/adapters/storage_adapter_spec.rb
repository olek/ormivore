require 'spec_helper'

require_relative 'shared_basic'
require_relative 'shared_expanded'
require_relative 'memory_helpers'
require_relative 'ar_helpers'
require_relative 'sequel_helpers'
require_relative 'redis_helpers'

describe 'account storage adapters' do
  let(:attrs) do
    v = test_value
    { firstname: v, lastname: v, email: v }
  end

  let(:test_attr) { :firstname }

  let(:factory_name) { :account }
  let(:factory_attrs) { {} }

  #let(:sql_storage_converter) {
  #  Class.new do
  #    self::STATUS_MAP = Hash.new { |h, k|
  #      raise ArgumentError, "Status #{k.inspect} not known"
  #    }.update(
  #      active: 1,
  #      inactive: 2,
  #      deleted: 3
  #    ).freeze

  #    self::REVERSE_STATUS_MAP = Hash.new { |h, k|
  #      raise ArgumentError, "Status #{k.inspect} not known"
  #    }.update(
  #      Hash[self::STATUS_MAP.to_a.map(&:reverse)]
  #    ).freeze

  #    def attributes_list_to_storage(list)
  #      list
  #    end

  #    def from_storage(attrs)
  #      attrs.dup.tap { |copy|
  #        copy[:status] = self.class::REVERSE_STATUS_MAP[copy[:status]] if copy[:status]
  #      }
  #    end

  #    def to_storage(attrs)
  #      attrs.dup.tap { |copy|
  #        copy[:status] = self.class::STATUS_MAP[copy[:status]] if copy[:status]
  #      }
  #    end
  #  end
  #}


  describe 'a memory adapter' do
    let(:described_class) { ORMivore::AnonymousFactory::create_memory_adapter }

    it_behaves_like 'an expanded adapter' do
      include MemoryHelpers
      let(:adapter) { described_class.new }
    end
  end

  describe 'an ActiveRecord adapter', :ar_db do
    let(:described_class) {
      ORMivore::AnonymousFactory::create_ar_adapter(
        'accounts')
    }

    it_behaves_like 'an expanded adapter' do
      include ArHelpers
      let(:entity_table) { 'accounts' }
      let(:adapter) { described_class.new }
    end
  end

  describe 'a Sequel adapter', :sequel_db do
    let(:described_class) {
      ORMivore::AnonymousFactory::create_sequel_adapter(
        'accounts')
    }

    it_behaves_like 'an expanded adapter' do
      include SequelHelpers
      let(:entity_table) { 'accounts' }
      let(:adapter) { described_class.new }
    end
  end

  describe 'a PreparedSequel adapter', :sequel_db do
    let(:described_class) {
      ORMivore::AnonymousFactory::create_prepared_sequel_adapter(
        'accounts')
    }

    it_behaves_like 'an expanded adapter' do
      include SequelHelpers
      let(:entity_table) { 'accounts' }
      let(:adapter) { described_class.new }
    end
  end

  describe 'a Redis adapter', :redis_db do
    let(:described_class) { ORMivore::AnonymousFactory::create_redis_adapter('accounts') }

    it_behaves_like 'a basic adapter' do
      include RedisHelpers
      let(:prefix) { 'accounts' }
      let(:adapter) { described_class.new }
    end
  end
end
