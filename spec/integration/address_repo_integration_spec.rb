require 'spec_helper'

module Helpers
  def execute_simple_int_query(query)
    execute_simple_string_query(query).to_i
  end

  def execute_simple_string_query(query)
    ActiveRecord::Base.connection.execute(query).first[0]
  end
end

describe App::AddressRepo do
  include Helpers

  subject {
    described_class.new(
      App::AddressStoragePort.new(
        App::AddressStorageArAdapter.new
      )
    )
  }

  let(:account_id) {
    FactoryGirl.create(:account).id
  }

  let(:attrs) do
    v = 'Foo'
    {
      street_1: v, city: v, postal_code: v,
      country_code: v, region_code: v,
      type: :shipping, account_id: account_id
    }
  end

  describe '#find_by_id' do
    it 'loads entity if found' do
      address = FactoryGirl.create(:shipping_address, street_1: 'Foo', addressable_id: account_id)
      subject.find_by_id(address.id).street_1.should == 'Foo'
    end

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

  describe '#persist' do
    context 'when entity is new' do
      it 'creates and returns new entity' do
        entity = App::Address.new(attrs)
        saved_entity = subject.persist(entity)
        saved_entity.should_not be_nil
        saved_entity.to_hash.should == attrs
        saved_entity.id.should be_kind_of(Integer)

        new_street_1 = execute_simple_string_query( "select street_1 from addresses where id = #{saved_entity.id}")
        new_street_1.should == attrs[:street_1]
      end
    end

    context 'when entity is not new' do
      let(:existing_entity_id) {
        FactoryGirl.create(:shipping_address, street_1: 'Dusty', addressable_id: account_id).id
      }

      it 'updates record in database' do
        entity = App::Address.new(attrs, existing_entity_id)
        saved_entity = subject.persist(entity)
        saved_entity.should_not be_nil
        saved_entity.to_hash.should == attrs
        saved_entity.id.should == existing_entity_id

        new_street_1 = execute_simple_string_query( "select street_1 from addresses where id = #{saved_entity.id}")
        new_street_1.should == attrs[:street_1]
      end
    end
  end
end
