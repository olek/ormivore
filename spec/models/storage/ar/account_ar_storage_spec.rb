require 'spec_helper'

module Helpers
  def execute_simple_int_query(query)
    execute_simple_string_query(query).to_i
  end

  def execute_simple_string_query(query)
    ActiveRecord::Base.connection.execute(query).first[0]
  end

  def new_account(attrs, id=nil)
    ORMivoreApp::Account.new(attrs.merge(id: id))
  end
end

describe ORMivoreApp::Storage::AR::AccountStorage do
  include Helpers

  let(:attrs) do
    v = 'Foo'
    { firstname: v, lastname: v, email: v, status: 1 }
  end

  let(:test_account) {
    FactoryGirl.create(:account)
  }


  it 'should respond to find_by_id' do
    described_class.should respond_to(:find_by_id)
  end

  describe '.find_by_id' do
    context 'when id points to non-existing account' do
      it 'should raise error' do
        expect {
          described_class.find_by_id(123456789)
        }.to raise_error ORMivore::RecordNotFound
      end
    end

    context 'when id points to existing account' do
      it 'should return proper account object' do
        account = described_class.find_by_id(test_account.id)
        account.should_not be_nil
        account.firstname.should == test_account.firstname
      end
    end
  end

  describe '.update' do
    context 'when record is new' do
      it 'should raise an error' do
        account = new_account(attrs)

        expect {
          described_class.update(account)
        }.to raise_error ORMivore::RecordNotFound
      end
    end

    context 'when record is not new' do
      it 'should update record attributes' do
        account = new_account(attrs, test_account.id)

        described_class.update(account)
        new_firstname = execute_simple_string_query( "select firstname from accounts where id = #{account.id}")

        new_firstname.should == 'Foo'
      end
    end

    context 'when record is not quite right' do
      it 'should raise an error' do
        pending
        test_account.instance_variable_set(:@attributes, { id: 'Abracadabra' })

        expect {
          described_class.update(account)
        }.to raise_error ORMivore::StorageError
      end
    end
  end
end

