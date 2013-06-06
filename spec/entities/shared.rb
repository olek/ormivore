shared_examples_for 'an entity' do
  subject { described_class.new(attrs) }

  let(:test_value) { 'Foo' }

  describe '#initialize' do
    it 'should fail if no attributes are provided' do
      expect {
        described_class.new
      }.to raise_error ArgumentError
    end

    it 'should fail if not enough attributes are provided' do
      expect {
        described_class.new(test_attr => test_value)
      }.to raise_error ORMivore::BadAttributesError
    end

    it 'should fail if unknown attributes are specified' do
       expect {
        described_class.new(attrs.merge(foo: 'Foo'))
      }.to raise_error ORMivore::BadAttributesError
    end

    it 'should allow specifying id' do
      o = described_class.new(attrs, 123)
      o.id.should == 123
    end

    it 'should allow string id that is convertable to integer' do
      o = described_class.new(attrs, '123')
      o.id.should == 123
    end

    it 'should refuse non-integer id' do
      expect {
        described_class.new(attrs, '123a')
      }.to raise_error ORMivore::BadArgumentError
    end

    context 'when all mandatory attributes are specified' do
      it 'should succeed' do
        o = described_class.new(attrs)
      end

      context 'when some of them are keyed by strings (not symbols)' do
        it 'should succeed' do
          attrs.except!(test_attr).merge!(test_attr.to_s => test_value)
          o = described_class.new(attrs)
        end
      end
    end
  end

  describe '#attributes' do
    it 'should return hash with all the model attributes keyed as symbols' do
      subject.attributes.should == attrs
    end
  end
end
