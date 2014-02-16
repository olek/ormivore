require 'spec_helper'
require_relative '../adapters/memory_helpers'
require_relative '../adapters/ar_helpers'
require_relative '../adapters/sequel_helpers'
require_relative '../adapters/redis_helpers'

shared_examples_for 'an integrated repo' do
  let(:attrs) do
    v = test_value
    { firstname: v, lastname: v, email: v }
  end

  let(:test_attr) { :firstname }
  let(:test_value) { 'Foo' }
  let(:other_test_value) { 'Bar' }

  def existing_entity_attrs
    FactoryGirl.create(:account, adapter: adapter, test_attr => test_value).
      attributes.symbolize_keys
  end

  let(:entity_class) {
    ORMivore::AnonymousFactory::create_entity do
      attributes do
        string :firstname, :lastname, :email
      end
    end
  }

  let(:port) {
    ORMivore::AnonymousFactory::create_port.new(adapter)
  }

  let(:repo) {
    ORMivore::AnonymousFactory::create_repo
  }

  subject { repo.new(entity_class, port) }

  describe '#find_by_id' do
    context 'when entity can be found' do
      it 'loads entity' do
        entity_attrs = existing_entity_attrs
        subject.find_by_id(entity_attrs[:id]).public_send(test_attr).should == test_value
      end
    end

    context 'when entity can not be found' do
      it 'raises error if entity is not found' do
        expect {
          subject.find_by_id(123)
        }.to raise_error ORMivore::RecordNotFound
      end

      context 'in quiet mode' do
        it 'returns nil if entity is not found' do
          subject.find_by_id(123, quiet: true).should be_nil
        end
      end
    end
  end

  describe '#find_all_by_id_as_hash' do
    context 'when all entities can be found' do
      it 'loads entities' do
        entity_attrs_1 = existing_entity_attrs
        entity_attrs_2 = existing_entity_attrs
        entity_id_1 = entity_attrs_1[:id]
        entity_id_2 = entity_attrs_2[:id]

        entities_map = subject.find_all_by_id_as_hash([entity_id_1, entity_id_2])
        entity1 = entities_map[entity_id_1]
        entity2 = entities_map[entity_id_2]

        entity1.id.should == entity_id_1
        entity2.id.should == entity_id_2
        entity1.public_send(test_attr).should == test_value
        entity2.public_send(test_attr).should == test_value
      end
    end

    context 'when entity can not be found' do
      it 'raises error if entity is not found' do
        expect {
          subject.find_all_by_id_as_hash([123])
        }.to raise_error ORMivore::RecordNotFound
      end

      context 'in quiet mode' do
        it 'returns empty hash if no entities are found' do
          subject.find_all_by_id_as_hash([123], quiet: true).should be_empty
        end

        it 'returns only found entities if not all entities are found' do
          entity_attrs_1 = existing_entity_attrs
          entity_id_1 = entity_attrs_1[:id]

          entities_map = subject.find_all_by_id_as_hash([entity_id_1, 124], quiet: true)

          entities_map.should have(1).entity
          entity1 = entities_map[entity_id_1]
          entity1.should_not be_nil
          entity1.id.should == entity_id_1
        end
      end
    end
  end

  describe '#persist' do
    context 'when entity is new' do
      it 'creates and returns new entity' do
        entity = entity_class.new.apply(attrs)
        saved_entity = subject.persist(entity)
        saved_entity.should_not be_nil
        saved_entity.attributes.should == attrs
        saved_entity.id.should be_kind_of(Integer)

        load_test_value(saved_entity.id).should == attrs[test_attr]
      end

      it 'creates entity with no "changes" recorded on it' do
        entity = entity_class.new.apply(attrs)
        entity.changes.should == attrs
        saved_entity = subject.persist(entity)
        saved_entity.changes.should be_empty
      end
    end

    context 'when entity is not new' do
      let(:existing_entity_id) {
        existing_entity_attrs[:id]
      }

      it 'updates record in database' do
        entity = entity_class.new(attributes: {}, id: existing_entity_id).apply(attrs)
        saved_entity = subject.persist(entity)
        saved_entity.should_not be_nil
        saved_entity.attributes.should == attrs
        saved_entity.id.should == existing_entity_id

        load_test_value(saved_entity.id).should == attrs[test_attr]
      end

      it 'creates entity with no "changes" recorded on it' do
        changes = { test_attr => other_test_value }
        entity = entity_class.new(attributes: attrs, id: existing_entity_id).apply(changes)
        entity.changes.should == changes
        saved_entity = subject.persist(entity)
        saved_entity.changes.should be_empty
      end
    end
  end
end

describe 'an entity and its ecosystem' do
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

  context 'with StorageMemoryAdapter', :memory_adapter do
    include MemoryHelpers

    let(:adapter) { ORMivore::AnonymousFactory::create_memory_adapter.new }

    it_behaves_like 'an integrated repo'
  end

  context 'with StorageArAdapter', :secondary_adapter, :ar_db do
    include ArHelpers

    let(:entity_table) { 'accounts' }
    let(:adapter) {
      ORMivore::AnonymousFactory::create_ar_adapter(
        'accounts').new
    }

    it_behaves_like 'an integrated repo'
  end

  context 'with StorageSequelAdapter', :secondary_adapter, :sequel_db do
    include SequelHelpers

    let(:entity_table) { 'accounts' }
    let(:adapter) {
      ORMivore::AnonymousFactory::create_sequel_adapter(
        'accounts').new
    }

    it_behaves_like 'an integrated repo'
  end

  context 'with StoragePreparedSequelAdapter', :sql_adapter, :sequel_db do
    include SequelHelpers

    let(:entity_table) { 'accounts' }
    let(:adapter) {
      ORMivore::AnonymousFactory::create_prepared_sequel_adapter(
        'accounts').new
    }

    it_behaves_like 'an integrated repo'
  end

  context 'with StorageRedisAdapter', :secondary_adapter, :redis_db do
    include RedisHelpers

    let(:prefix) { 'accounts' }
    let(:adapter) { ORMivore::AnonymousFactory::create_redis_adapter('accounts').new }

    it_behaves_like 'an integrated repo'
  end
end
