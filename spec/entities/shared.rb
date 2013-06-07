shared_examples_for 'an entity' do
  subject { described_class.new(attrs) }

  let(:test_value) { 'Foo' }

  describe '#initialize' do
    it 'fails if no attributes are provided' do
      expect {
        described_class.new
      }.to raise_error ArgumentError
    end

    it 'fails if not enough attributes are provided' do
      expect {
        described_class.new(test_attr => test_value)
      }.to raise_error ORMivore::BadAttributesError
    end

    it 'fails if unknown attributes are specified' do
       expect {
        described_class.new(attrs.merge(foo: 'Foo'))
      }.to raise_error ORMivore::BadAttributesError
    end

    it 'allows specifying id' do
      o = described_class.new(attrs, 123)
      o.id.should == 123
    end

    it 'allows string id that is convertable to integer' do
      o = described_class.new(attrs, '123')
      o.id.should == 123
    end

    it 'refuses non-integer id' do
      expect {
        described_class.new(attrs, '123a')
      }.to raise_error ORMivore::BadArgumentError
    end

    context 'when all mandatory attributes are specified' do
      it 'succeeds' do
        o = described_class.new(attrs)
      end

      context 'when some of them are keyed by strings (not symbols)' do
        it 'succeeds' do
          attrs.except!(test_attr).merge!(test_attr.to_s => test_value)
          o = described_class.new(attrs)
        end
      end
    end

    context 'when id is specified' do
      it 'assumes first param attributes to be "clean" attributes' do
        o = described_class.new(attrs, 123)
        o.changes.should be_empty
      end

      it 'allows specifying "dirty" attributes' do
        o = described_class.new(attrs, 123, test_attr => 'dirty')
        o.changes.should_not be_empty
        o.changes.should == { test_attr => 'dirty' }
      end
    end
  end

  describe '#attributes' do
    it 'returns hash with all the model attributes keyed as symbols' do
      subject.attributes.should == attrs
    end

    it 'combines clean and dirty attributes' do
      o = described_class.new(attrs, 123, test_attr => 'dirty')
      o.attributes.should == attrs.merge(test_attr => 'dirty')
    end
  end

  describe 'attribute methods' do
    it 'return value of attribute' do
      subject.public_send(test_attr).should == test_value
    end

    it 'return dirty value of attribute if available' do
      o = described_class.new(attrs, 123, test_attr => 'dirty')
      o.changes.should == { test_attr => 'dirty' }
      o.public_send(test_attr).should == 'dirty'
    end
  end

  describe '#create' do
    it 'delegates to constructor' do
      subject.create(attrs).should be_kind_of(described_class)
    end
  end

  describe '#prototype' do
    subject { described_class.new(attrs, 123) }

    it 'creates copy of this entity' do
      proto = subject.prototype({})
      proto.should_not == subject
      proto.attributes.should == subject.attributes
    end

    it 'adds changes to the copy it makes' do
      proto = subject.prototype(test_attr => 'dirty')
      proto.attributes.should == attrs.merge(test_attr => 'dirty')
    end
  end

  describe '#changes' do
    it 'returns all attributes on new entity' do
      subject.changes.should == attrs
    end

    it 'returns no attributes on "persisted" entity' do
      described_class.new(attrs, 123).changes.should be_empty
    end

    it 'returns incremental changes added by prototyping' do
      o = described_class.new(attrs, 123)
      o.prototype(test_attr => 'dirty').changes.should == { test_attr => 'dirty' }
    end
  end
end
