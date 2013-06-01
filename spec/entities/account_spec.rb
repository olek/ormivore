require 'spec_helper'

describe ORMivoreApp::Account do
  let(:attributes) do
    v = 'Foo'
    { firstname: v, lastname: v, email: v, status: :active }
  end

  subject { described_class.new(attributes) }

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
    it 'should return proper symbol' do
      subject.status.should == :active
    end
  end

  describe '#attributes' do
    it 'should return hash with all the model attributes keyed as symbols' do
      subject.to_hash.should == attributes
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
