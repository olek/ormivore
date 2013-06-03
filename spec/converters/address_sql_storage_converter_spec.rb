require 'spec_helper'

describe App::AddressSqlStorageConverter do
  let(:attrs) do
    v = 'Foo'
    {
      street_1: v, city: v, postal_code: v,
      country_code: v, region_code: v
    }
  end

  describe '#from_storage' do
    it 'converts type attribute' do
      subject.from_storage(attrs.merge(type: 'ShippingAddress')).should include(type: :shipping)
      subject.from_storage(attrs.merge(type: 'BillingAddress')).should include(type: :billing)
    end

    it 'converts addressable id/type attributes to account_id' do
      subject.from_storage(attrs.merge(addressable_type: 'Account', addressable_id: 123)).should include(account_id: 123)
    end

    it 'raises error converting unknown addressable_type' do
      expect {
        subject.from_storage(attrs.merge(addressable_type: 'Foo', addressable_id: 123))
      }.to raise_error ORMivore::BadArgumentError
    end

    it 'passes through other attributes' do
      subject.from_storage(attrs).should == attrs
    end
  end

  describe '#to_storage' do
    it 'converts status attribute' do
      subject.to_storage(attrs.merge(type: :shipping)).should include(type: 'ShippingAddress')
      subject.to_storage(attrs.merge(type: :billing)).should include(type: 'BillingAddress')
    end

    it 'converts account_id to addressable_id/type attributes' do
      subject.to_storage(attrs.merge(account_id: 123)).should include(addressable_type: 'Account', addressable_id: 123)
    end

    it 'passes through other attributes' do
      subject.to_storage(attrs).should == attrs
    end
  end
end

