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

=begin
  describe '.create' do
    context 'when record is not new' do
      it 'should raise an error' do
        expect {
          described_class.create(new_account(attrs).tap { |a| a.id = 11 })
        }.to raise_error ORMivore::RecordAlreadyExists
      end
    end

    it 'should insert record to database' do
      described_class.create(new_account(attrs.merge(firstname: 'Foo')))
      account_id = execute_simple_int_query("select id from accounts where firstname = 'Foo'")
      account_id.should be > 0
    end

    context 'when record is not quite right' do
      it 'should raise an error' do
        # TODO verify if this test in meaningfull
        account = new_account(attrs)
        account.instance_variable_set(:@attributes, { firstname: 'Bob' })

        expect {
          described_class.create(account)
          account_id = execute_simple_int_query("select id from accounts where firstname = 'Foo'")
          account_id.should == 0
        }.to raise_error ORMivore::StorageError
      end
    end
  end
=end

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
        # this test would work if MySql was working in STRICT sql_mode, but it is not...
        account_id = execute_simple_int_query( "select id from accounts where firstname = 'something' limit 1")
        account_id.should_not be_zero
        account = new_account(attrs, account_id)

        account.instance_variable_set(:@attributes, { status: 1, firstname: nil })

        expect {
          described_class.update(account)
        }.to raise_error ORMivore::StorageError
      end
    end
  end
end

