require 'spec_helper'

describe ORMivoreApp::Address do
  let(:attributes) do
    v = 'Foo'
    {
      street_1: v, city: v, postal_code: v,
      country_code: v, region_code: v,
      type: :shipping, account_id: 1
    }
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
        described_class.new(street_1: 'Foo')
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
          attrs = attributes.except(:street_1).merge('street_1' => 'street')
          o = described_class.new(attrs)
        end
      end
    end
  end

  describe '#street_1' do
    it 'should return first line of street address' do
      attrs = attributes.merge(street_1: 'street')
      o = described_class.new(attrs)
      o.street_1.should == 'street'
    end
  end

  describe '#type' do
    it 'should return either shipping or billing type' do
      subject.type.should == :shipping
    end
  end

  describe '#attributes' do
    it 'should return hash with all the model attributes keyed as symbols' do
      subject.to_hash.should == attributes
    end
  end

=begin
  describe '.storage' do
    it 'should point to AR storage by default' do
      described_class.storage.should == ORMivoreApp::Storage::AR::AddressStorage
    end
  end

  describe '.find_by_account_id' do
    it 'should exist' do
      described_class.should respond_to(:find_by_account_id)
    end

    it 'should delegate actual work to storage' do
      storage.should_receive(:find_by_account_id).with(11).and_return('foo')
      described_class.find_by_account_id(11).should == 'foo'
    end
  end

  describe '#save' do
    context 'when model is new' do
      it 'should delegate to create operation on storage' do 
        storage.should_receive(:create).with(subject)
        subject.save
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
=end
end

=begin
describe ORMivore::Address do
  describe "#validate_required_fields" do
    it "should tell us the fields that we need" do
      shipping = ORMivore::ShippingAddress.new
      shipping.validate_required_fields
      errors = shipping.errors.full_messages
      errors.should_not be_empty

      errors.should include("Firstname cannot be left blank")
      errors.should include("Lastname cannot be left blank")
      errors.should include("City cannot be left blank")
      errors.should include("Region cannot be left blank")
      errors.should include("Postal code cannot be left blank")
      errors.should include("Street 1 cannot be left blank")
    end

    it "should be totally valid" do
      shipping = ORMivore::ShippingAddress.new(:firstname => "test", :lastname => "test", :city =>"test",
                                                    :region => ORMivore::Region.new, :postal_code =>"15243", :street_1 => "123 test lane")
      shipping.validate_required_fields
      errors = shipping.errors
      errors.should be_empty
    end
  end
end
=end
