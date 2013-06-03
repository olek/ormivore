require 'spec_helper'

module Helpers
  def execute_simple_int_query(query)
    execute_simple_string_query(query).to_i
  end

  def execute_simple_string_query(query)
    ActiveRecord::Base.connection.execute(query).first[0]
  end
end

describe App::AccountRepo do
  include Helpers

  subject {
    described_class.new(
      App::AccountStoragePort.new(
        App::AccountStorageArAdapter.new
      )
    )
  }

  let(:attrs) do
    v = 'Foo'
    { firstname: v, lastname: v, email: v, status: :active }
  end

  describe '#find_by_id' do
    it 'loads entity if found' do
      account = FactoryGirl.create(:account, firstname: 'Foo')
      subject.find_by_id(account.id).firstname.should == 'Foo'
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
        entity = App::Account.new(attrs)
        saved_entity = subject.persist(entity)
        saved_entity.should_not be_nil
        saved_entity.to_hash.should == attrs
        saved_entity.id.should be_kind_of(Integer)

        new_firstname = execute_simple_string_query( "select firstname from accounts where id = #{saved_entity.id}")
        new_firstname.should == attrs[:firstname]
      end
    end

    context 'when entity is not new' do
      let(:existing_entity_id) {
        FactoryGirl.create(:account, firstname: 'Dusty').id
      }

      it 'updates record in database' do
        entity = App::Account.new(attrs, existing_entity_id)
        saved_entity = subject.persist(entity)
        saved_entity.should_not be_nil
        saved_entity.to_hash.should == attrs
        saved_entity.id.should == existing_entity_id

        new_firstname = execute_simple_string_query( "select firstname from accounts where id = #{saved_entity.id}")
        new_firstname.should == attrs[:firstname]
      end
    end
  end
end
