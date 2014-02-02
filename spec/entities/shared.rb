shared_examples_for 'an entity' do
  subject { described_class.new(attributes: attrs, id: 123) }

  let(:test_value) { 'Foo' }

  describe '#initialize' do
    it 'succeeds if no options are specified' do
      described_class.new
    end

    it 'succeeds if empty options are specified' do
      described_class.new({})
    end

    it 'succeeds when only repo is provided' do
      described_class.new(repo: 'Pretend repo')
    end

    it 'fails if unknown attributes are specified' do
       expect {
        described_class.new(attributes: attrs.merge(foo: 'Foo'), id: 123)
      }.to raise_error ORMivore::BadAttributesError
    end

    it 'allows specifying id' do
      o = described_class.new(id: 123)
      o.id.should == 123
    end

    it 'allows string id that is convertable to integer' do
      o = described_class.new(id: '123')
      o.id.should == 123
    end

    it 'refuses non-integer id' do
      expect {
        described_class.new(id: '123a')
      }.to raise_error ORMivore::BadArgumentError
    end

    context 'when all mandatory attributes are specified' do
      it 'succeeds' do
        o = described_class.new(attributess: attrs)
      end

      context 'when some of them are keyed by strings (not symbols)' do
        it 'succeeds' do
          attrs.except!(test_attr).merge!(test_attr.to_s => test_value)
          o = described_class.new(attributess: attrs)
        end
      end
    end
  end

  describe '#validate' do
    it 'fails if not enough attributes are provided' do
      entity = described_class.new(attributes: { test_attr => test_value }, id: 123)
      expect {
        entity.validate
      }.to raise_error ORMivore::BadAttributesError
    end

    it 'succeeds when all mandatory attributes are specified' do
      described_class.new(attributes: attrs, id: 123).validate
    end
  end

  describe '#attributes' do
    it 'returns hash with all the model attributes keyed as symbols' do
      subject.attributes.should == attrs
    end

    it 'combines attributes from this and parent properties' do
      o = described_class.new(attributes: attrs, id: 123).apply(test_attr => 'dirty')
      o.attributes.should == attrs.merge(test_attr => 'dirty')
    end
  end

  describe '#attribute' do
    it 'returns nil for not found attribute' do
      attrs.except!(test_attr)
      subject.attribute(test_attr).should be_nil
    end

    it 'fails for unknown attribute' do
      expect {
        subject.attribute(:foo)
      }.to raise_error ORMivore::BadArgumentError
    end

    it 'returns nil for attribute that was reset to nil' do
      o = subject.apply(test_attr => nil)
      o.attribute(test_attr).should be_nil
    end

    it 'returns attribute from this entity if found' do
      o = subject.apply(test_attr => 'dirty')
      o.attribute(test_attr).should == 'dirty'
    end

    it 'returns attribute from parent entity if found' do
      o = subject.apply(test_attr => 'dirty')
      o.attribute(other_test_attr).should == test_value
    end
  end

  describe 'attribute methods' do
    it 'return value of attribute' do
      subject.public_send(test_attr).should == test_value
    end

    it 'return dirty value of attribute if available' do
      o = described_class.new(attributes: attrs, id: 123).apply(test_attr => 'dirty')
      o.changes.should == { test_attr => 'dirty' }
      o.public_send(test_attr).should == 'dirty'
    end
  end

  describe '#apply' do
    it 'creates copy of this entity when changes present' do
      proto = subject.apply(test_attr => 'dirty')
      proto.should_not be(subject)
      proto.attributes.should == subject.attributes.merge(test_attr => 'dirty')
    end

    it 'returns self if no changes applied' do
      proto = subject.apply({})
      proto.should == subject
    end

    it 'returns self if attributes are changing to same values' do
      proto = subject.apply(test_attr => test_value)
      proto.should == subject
    end

    it 'adds changes to the copy it makes' do
      proto = subject.apply(test_attr => 'dirty')
      proto.attributes.should == attrs.merge(test_attr => 'dirty')
    end
  end

  describe '#changes' do
    it 'returns empty hash on new entity' do
      described_class.new.changes.should be_empty
    end

    it 'returns no attributes on "persisted" entity' do
      subject.changes.should be_empty
    end

    it 'returns incremental changes added by applying attributes' do
      subject.apply(test_attr => 'dirty').changes.should == { test_attr => 'dirty' }
    end
  end

  describe '#attach_repo' do
    it 'attaches repo to entity that lacks it' do
      described_class.new.attach_repo(:foo).repo.should == :foo
    end

    it 'attaches repo to parent of the entity too' do
      parent = described_class.new
      parent.apply(test_attr => test_value).attach_repo(:foo)
      parent.repo.should == :foo
    end

    it 'raises error if entity already has repo' do
      expect {
        described_class.new(repo: :foo).attach_repo(:bar)
      }.to raise_error ORMivore::InvalidStateError
    end
  end
end
