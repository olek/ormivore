require 'spec_helper'

module Helpers
  def execute_simple_int_query(query)
    execute_simple_string_query(query).to_i
  end

  def execute_simple_string_query(query)
    ActiveRecord::Base.connection.execute(query).first[0]
  end
end

describe App::AddressStorageArAdapter do
  include Helpers

  subject { described_class.new(App::NoopConverter.new) }

  let(:attrs) do
    v = 'Foo'
    {
      street_1: v, city: v, postal_code: v,
      country_code: v, region_code: v,
      type: :shipping
    }
  end

  it 'responds to find' do
    subject.should respond_to(:find)
  end

  describe '#find' do
    context 'when conditions points to non-existing address' do
      it 'should raise error' do
        expect {
          subject.find(id: 123456789)
        }.to raise_error ORMivore::RecordNotFound
      end
    end

    context 'when id points to existing address' do
      it 'should return proper address attrs' do
        account = FactoryGirl.create(:account)
        address = FactoryGirl.create(:shipping_address, addressable_id: account.id, addressable_type: 'Account')
        data = subject.find(id: address.id)
        data.should_not be_nil
        data[:street_1].should == address.street_1
      end
    end
  end

  describe '#create' do
    let(:account) {
      FactoryGirl.create(:account)
    }

    let(:attrs) {
      v = 'Foo'
      {
        street_1: v, city: v, postal_code: v,
        country_code: v, region_code: v,
        type: :shipping, addressable_id: account.id, addressable_type: 'Account'
      }
    }

    context 'when attempting to create record with id that is already present in database' do
      it 'raises error' do
        expect {
          subject.create(subject.create(attrs))
        }.to raise_error ActiveRecord::StatementInvalid
      end
    end

    context 'when record does not have an id' do
      it 'returns back attributes including new id' do
        data = subject.create(attrs)
        data.should include(attrs)
        data[:id].should be_kind_of(Integer)
      end

      it 'inserts record in database' do
        data = subject.create(attrs)

        new_street_1 = execute_simple_string_query( "select street_1 from addresses where id = #{data[:id]}")
        new_street_1.should == 'Foo'
      end
    end
  end

  describe '#update' do
    context 'when record did not exist' do
      it 'returns 0 update count' do
        FactoryGirl.create(:account_with_shipping_address)
        subject.update(attrs, id: 123).should == 0
      end
    end

    context 'when record existed' do
      it 'returns update count 1' do
        account = FactoryGirl.create(:account)
        FactoryGirl.create(:shipping_address, addressable_id: account.id, addressable_type: 'Account')
        address = FactoryGirl.create(:shipping_address, addressable_id: account.id, addressable_type: 'Account')

        subject.update(attrs, id: address.id).should == 1
      end

      it 'updates record attributes' do
        account = FactoryGirl.create(:account)
        address = FactoryGirl.create(:shipping_address, addressable_id: account.id, addressable_type: 'Account')

        subject.update(attrs, id: address.id)

        new_street_1 = execute_simple_string_query( "select street_1 from addresses where id = #{address.id}")
        new_street_1.should == 'Foo'
      end
    end

    context 'when 2 matching records existed' do
      it 'returns update count 2' do
        account = FactoryGirl.create(:account)
        address_ids = []
        address_ids << FactoryGirl.create(:shipping_address, addressable_id: account.id, addressable_type: 'Account').id
        address_ids << FactoryGirl.create(:shipping_address, addressable_id: account.id, addressable_type: 'Account').id

        subject.update(attrs, id: address_ids).should == 2
      end
    end

    context 'when conditions to update are not quite right' do
      it 'should raise an error' do
        expect {
          subject.update(attrs, foo: 'bar')
        }.to raise_error ActiveRecord::StatementInvalid
      end
    end
  end
end
