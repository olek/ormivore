require 'spec_helper'

module Helpers
  def execute_simple_int_query(query)
    execute_simple_string_query(query).to_i
  end

  def execute_simple_string_query(query)
    ActiveRecord::Base.connection.execute(query).first[0]
  end
end

describe ORMivoreApp::AccountStorageArAdapter do
  include Helpers

  subject { described_class.new(ORMivoreApp::NoopConverter.new) }

  let(:attrs) do
    v = 'Foo'
    { firstname: v, lastname: v, email: v, status: 1 }
  end

  it 'responds to find' do
    subject.should respond_to(:find)
  end

  describe '#find' do
    context 'when conditions points to non-existing account' do
      it 'should raise error' do
        expect {
          subject.find(id: 123456789)
        }.to raise_error ORMivore::RecordNotFound
      end
    end

    context 'when id points to existing account' do
      it 'should return proper account attrs' do
        account = FactoryGirl.create(:account)
        data = subject.find(id: account.id)
        data.should_not be_nil
        data[:firstname].should == account.firstname
      end
    end
  end

  describe '#create' do
    let(:attrs) do
      v = 'Foo'
      { firstname: v, lastname: v, email: v, status: 1 }
    end

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

        new_firstname = execute_simple_string_query( "select firstname from accounts where id = #{data[:id]}")
        new_firstname.should == 'Foo'
      end
    end
  end

  describe '#update' do
    context 'when record did not exist' do
      it 'returns 0 update count' do
        FactoryGirl.create(:account)
        subject.update(attrs, id: 123).should == 0
      end
    end

    context 'when record existed' do
      it 'returns update count 1' do
        FactoryGirl.create(:account)
        account = FactoryGirl.create(:account)

        subject.update(attrs, id: account.id).should == 1
      end

      it 'updates record attributes' do
        account = FactoryGirl.create(:account)

        subject.update(attrs, id: account.id)

        new_firstname = execute_simple_string_query( "select firstname from accounts where id = #{account.id}")
        new_firstname.should == 'Foo'
      end
    end

    context 'when 2 matching records existed' do
      it 'returns update count 2' do
        account_ids = []
        account_ids << FactoryGirl.create(:account).id
        account_ids << FactoryGirl.create(:account).id

        subject.update(attrs, id: account_ids).should == 2
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
