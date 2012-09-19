require 'spec_helper'

module Helpers
  def execute_simple_int_query(query)
    execute_simple_string_query(query)
  end

  def execute_simple_string_query(query)
    ActiveRecord::Base.connection.execute(query).first[0]
  end

  def new_address(attrs, id=nil)
    ORMivoreApp::Address.new(attrs.merge(id: id))
  end
end

describe ORMivoreApp::Storage::AR::AddressStorage do
  include Helpers

  Addressable = Struct.new(:id)

  let(:attrs) do
    v = 'Foo'
    {
      street_1: v, city: v, postal_code: v, country_code: v, region_code: v,
      type: :shipping, addressable: Addressable.new(0)
    }
  end

  let(:account) {
    FactoryGirl.create(:account)
  }


  it 'should respond to find_by_account_id' do
    described_class.should respond_to(:find_by_account_id)
  end

  describe '.find_by_account_id' do
    context 'when id points to non-existing account' do
      it 'should return nil' do
        addr = described_class.find_by_account_id(123456789)
        addr.should be_nil
      end
    end

    context 'when id points to existing account' do
      context 'when account does not have a shipping address' do
        it 'should return nil' do
          addr = described_class.find_by_account_id(account.id)
          addr.should be_nil
        end
      end

      context 'when account actually has shipping address' do
        it 'should return proper shipping address' do
          db_addr = FactoryGirl.create(:shipping_address, addressable_id: account.id, addressable_type: 'Account', postal_code: '11')
          addr = described_class.find_by_account_id(account.id)
          addr.should_not be_nil
          addr.postal_code.should == '11'
          addr.id.should == db_addr.id
        end
      end
    end
  end

  describe '.create' do
    context 'when record is not new' do
      it 'should raise an error' do
        expect {
          described_class.create(new_address(attrs, 11))
        }.to raise_error ORMivore::RecordAlreadyExists
      end
    end

    it 'should insert record to database' do
      described_class.create(new_address(attrs.merge(city: 'Foo')))
      address_id = execute_simple_int_query("select id from addresses where city = 'Foo'")
      address_id.should be > 0
    end

    context 'when record is not quite right' do
      it 'should raise an error' do
        address = new_address(attrs)
        address.should_receive(:to_hash).and_return({ type: :shipping })

        expect {
          described_class.create(address)
          address_id = execute_simple_int_query("select id from addresses where city = 'Foo'")
          address_id.should == 0
        }.to raise_error ORMivore::StorageError
      end
    end
  end

  describe '.update' do
    context 'when record is new' do
      it 'should raise an error' do
        address = new_address(attrs)

        expect {
          described_class.update(address)
        }.to raise_error ORMivore::RecordNotFound
      end
    end

    context 'when record is not new' do
      it 'should update record attributes' do
        address = FactoryGirl.create(:shipping_address, addressable_id: account.id, addressable_type: 'Account', postal_code: '11')
        address = new_address(attrs, address.id)

        described_class.update(address)
        new_city = execute_simple_string_query( "select city from addresses where id = #{address.id}")

        new_city.should == 'Foo'
      end
    end

    context 'when record is not quite right' do
      it 'should raise an error' do
        pending
        # this test would work if MySql was working in STRICT sql_mode, but it is not...
        address_id = execute_simple_int_query( "select id from addresses where city = 'Pittsburgh' limit 1")
        address_id.should_not be_zero
        address = new_address(attrs, address_id)

        address.instance_variable_set(:@attributes, { type: :shipping, city: nil })

        expect {
          described_class.update(address)
        }.to raise_error ORMivore::StorageError
      end
    end
  end
end
