require 'spec_helper'

describe App::AccountSqlStorageConverter do
  let(:attrs) do
    v = 'Foo'
    { firstname: v, lastname: v, email: v }
  end

  describe '#from_storage' do
    it 'converts status attribute' do
      subject.from_storage(attrs.merge(status: 1)).should include(status: :active)
    end

    it 'passes through other attributes' do
      subject.from_storage(attrs.merge(status: 1)).should include(attrs)
    end
  end

  describe '#to_storage' do
    it 'converts status attribute' do
      subject.to_storage(attrs.merge(status: :inactive)).should include(status: 2)
    end

    it 'passes through other attributes' do
      subject.to_storage(attrs.merge(status: :inactive)).should include(attrs)
    end
  end
end
