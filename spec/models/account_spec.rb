require 'spec_helper'

describe ORMivoreApp::Account do
  let(:attributes) do
    v = 'Foo'
    { firstname: v, lastname: v, email: v, status: 1 }
  end

  subject { described_class.new(attributes) }

  let(:storage) do
    double(:storage).tap do |storage|
      described_class.stub(:storage).and_return(storage)
    end
  end

  describe '.find_by_id' do
    it 'should exist' do
      described_class.should respond_to(:find_by_id)
    end

    it 'should delegate actual work to storage' do
      storage.should_receive(:find_by_id).with(11).and_return('foo')
      described_class.find_by_id(11).should == 'foo'
    end
  end

  describe '#initialize' do
    it 'should fail if no attributes are provided' do
      expect {
        described_class.new
      }.to raise_error ArgumentError
    end

    it 'should fail if not enough attributes are provided' do
      expect {
        described_class.new(firstname: 'Foo')
      }.to raise_error ORMivore::BadArgumentError
    end

    it 'should fail if unknown attributes are specified' do
       expect {
        described_class.new(attributes.merge(foo: 'Foo'))
      }.to raise_error ORMivore::BadArgumentError
    end

    context 'when all mandatory attributes are specified' do
      it 'should succeed' do
        o = described_class.new(attributes)
      end

      context 'when some of them are keyed by strings (not symbols)' do
        it 'should succeed' do
          attrs = attributes.except(:street_1).merge('firstname' => 'Foo')
          o = described_class.new(attrs)
        end
      end
    end
  end

  describe '#firstname' do
    it 'should return first name' do
      attrs = attributes.merge(firstname: 'Bob')
      o = described_class.new(attrs)
      o.firstname.should == 'Bob'
    end
  end

  describe '#status' do
    it 'should return integer' do
      subject.status.should == 1
    end
  end

  describe '#attributes' do
    it 'should return hash with all the model attributes keyed as symbols' do
      subject.to_hash.should == attributes
    end
  end

  describe '.storage' do
    it 'should point to AR storage by default' do
      described_class.storage.should == ORMivoreApp::Storage::AR::AccountStorage
    end
  end

  describe '#save' do
    context 'when model is new' do
      it 'should raise error' do 
        expect {
          subject.save
        }.to raise_error ORMivore::NotImplementedYet
      end
    end
    context 'when model exists' do
      it 'should delegate to update operation on storage' do
        o = described_class.new(attributes.merge(id: 11))
        storage.should_receive(:update).with(o)
        o.save
      end
    end
  end
end

=begin
describe ORMivore::Account do
  context "scopes" do
    describe "#active" do
      before(:each) do
        @active = mock(ORMivore::Account, :status => 1)
        @inactive = mock(ORMivore::Account, :status => 3)
        @accounts = [@active, @inactive]
      end
      xit "should work!" do
        ORMivore::Account.should_receive(:all).and_return(@accounts)
        ORMivore::Account.active.should_not include(@inactive)
      end
    end
  end
end
=end
