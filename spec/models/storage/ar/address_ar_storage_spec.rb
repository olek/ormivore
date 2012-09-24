require 'spec_helper'

module Helpers
  def execute_simple_int_query(query)
    Integer(execute_simple_string_query(query))
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

  subject { described_class }

  Addressable = Struct.new(:id)

  let(:attrs) do
    v = 'Foo'
    {
      street_1: v, city: v, postal_code: v, country_code: v, region_code: v,
      type: :shipping, addressable: Addressable.new(999)
    }
  end

  let(:account) {
    FactoryGirl.create(:account)
  }


  it 'should respond to find_by_account_id' do
    subject.should respond_to(:find_by_account_id)
  end

  describe '.find_by_account_id' do
    context 'when id points to non-existing account' do
      it 'should return nil' do
        subject.find_by_account_id(123456789).should be_nil
      end
    end

    context 'when id points to existing account' do
      context 'when account does not have a shipping address' do
        it 'should return nil' do
          subject.find_by_account_id(account.id).should be_nil
        end
      end

      context 'when account actually has shipping address' do
        it 'should return proper shipping address' do
          db_addr = FactoryGirl.create(:shipping_address, addressable_id: account.id, postal_code: '11')
          addr = subject.find_by_account_id(account.id)
          addr.should_not be_nil
          addr.postal_code.should == '11'
          addr.id.should == db_addr.id
        end
      end
    end
  end

  describe '.create' do
    context 'when record already has primary key assigned' do
      it 'should raise an error' do
        expect {
          subject.create(new_address(attrs, 11))
        }.to raise_error ORMivore::RecordAlreadyExists
      end
    end

    it 'should insert record to database' do
      subject.create(new_address(attrs.merge(city: 'Pittsburgh')))
      address_id = execute_simple_int_query("select id from addresses where city = 'Pittsburgh'")
      address_id.should be > 0
    end

    context 'when record is not quite right' do
      it 'should raise an error' do
        address = new_address(attrs.merge(addressable: Addressable.new('Abracadabra')))

        expect {
          subject.create(address)
        }.to raise_error ORMivore::StorageError
      end
    end
  end

  describe '.update' do
    context 'when record is new' do
      it 'should raise an error' do
        address = new_address(attrs)

        expect {
          subject.update(address)
        }.to raise_error ORMivore::RecordNotFound
      end
    end

    context 'when record is not new' do
      it 'should update record attributes' do
        address = FactoryGirl.create(:shipping_address, addressable_id: 999, postal_code: '11')
        address = new_address(attrs, address.id)

        subject.update(address)
        new_city = execute_simple_string_query( "select city from addresses where id = #{address.id}")

        new_city.should == 'Foo'
      end
    end

    context 'when record is not quite right' do
      it 'should raise an error' do
        address = FactoryGirl.create(:shipping_address, addressable_id: 999, postal_code: '11')
        address = new_address(attrs, address.id)

        address.instance_variable_set(:@attributes, { addressable_id: 'Abracadabra' })

        expect {
          subject.update(address)
        }.to raise_error ORMivore::StorageError
      end
    end
  end
end
