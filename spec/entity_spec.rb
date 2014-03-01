require 'spec_helper'

describe 'an entity' do
  let(:test_value) { 'Foo' }

  let(:attrs) do
    { attr_1: test_value, attr_2: test_value }
  end

  let(:described_class) {
    ORMivore::AnonymousFactory::create_entity do
      attributes do
        string :attr_1, :attr_2
      end
    end
  }

  subject { described_class.new_root(attributes: attrs, id: 123) }

  describe '.shorthand' do
    context 'when shorthand was previously not set' do
      it 'returns nil' do
        described_class.shorthand_notation.should be_nil
      end
    end

    context 'when shorthand was previously set to symbol' do
      let(:described_class) {
        ORMivore::AnonymousFactory::create_entity do
          shorthand :foo
        end
      }
      it 'returns previously set shorthand' do
        described_class.shorthand_notation.should == :foo
      end
    end

    context 'when shorthand was previously set to string' do
      let(:described_class) {
        ORMivore::AnonymousFactory::create_entity do
          shorthand 'foo'
        end
      }
      it 'returns previously set shorthand as symbol' do
        described_class.shorthand_notation.should == :foo
      end
    end
  end

  describe '#initialize' do
    it 'succeeds if no options are specified' do
      described_class.new_root
    end

    it 'succeeds if empty options are specified' do
      described_class.new_root({})
    end

    it 'succeeds when only repo is provided' do
      described_class.new_root(repo: 'Pretend repo')
    end

    it 'fails if unknown attributes are specified' do
       expect {
        described_class.new_root(attributes: attrs.merge(foo: 'Foo'), id: 123)
      }.to raise_error ORMivore::BadAttributesError
    end

    it 'allows specifying id' do
      o = described_class.new_root(id: 123)
      o.id.should == 123
    end

    it 'allows string id that is convertable to integer' do
      o = described_class.new_root(id: '123')
      o.id.should == 123
    end

    it 'refuses non-integer id' do
      expect {
        described_class.new_root(id: '123a')
      }.to raise_error ORMivore::BadArgumentError
    end

    context 'when all mandatory attributes are specified' do
      it 'succeeds' do
        o = described_class.new_root(attributess: attrs)
      end

      context 'when some of them are keyed by strings (not symbols)' do
        it 'succeeds' do
          attrs.except!(:attr_1).merge!('attr_1' => test_value)
          o = described_class.new_root(attributess: attrs)
        end
      end
    end
  end

  describe '#validate' do
    it 'fails if not enough attributes are provided' do
      entity = described_class.new_root(attributes: { attr_1: test_value }, id: 123)
      expect {
        entity.validate
      }.to raise_error ORMivore::BadAttributesError
    end

    it 'succeeds when all mandatory attributes are specified' do
      described_class.new_root(attributes: attrs, id: 123).validate
    end
  end

  describe '#attributes' do
    it 'returns hash with all the model attributes keyed as symbols' do
      subject.attributes.should == attrs
    end

    it 'combines attributes from this and parent properties' do
      o = described_class.new_root(attributes: attrs, id: 123).apply(attr_1: 'dirty')
      o.attributes.should == attrs.merge(attr_1: 'dirty')
    end
  end

  describe '#attribute' do
    it 'returns nil for not found attribute' do
      attrs.except!(:attr_1)
      subject.attribute(:attr_1).should be_nil
    end

    it 'fails for unknown attribute' do
      expect {
        subject.attribute(:foo)
      }.to raise_error ORMivore::BadArgumentError
    end

    it 'returns nil for attribute that was reset to nil' do
      o = subject.apply(attr_1: nil)
      o.attribute(:attr_1).should be_nil
    end

    it 'returns attribute from this entity if found' do
      o = subject.apply(attr_1: 'dirty')
      o.attribute(:attr_1).should == 'dirty'
    end

    it 'returns attribute from parent entity if found' do
      o = subject.apply(attr_1: 'dirty')
      o.attribute(:attr_2).should == test_value
    end
  end

  describe 'attribute methods' do
    it 'return value of attribute' do
      subject.public_send(:attr_1).should == test_value
    end

    it 'return dirty value of attribute if available' do
      o = described_class.new_root(attributes: attrs, id: 123).apply(attr_1: 'dirty')
      o.changes.should == { attr_1: 'dirty' }
      o.public_send(:attr_1).should == 'dirty'
    end
  end

  describe '#apply' do
    it 'creates copy of this entity when changes present' do
      proto = subject.apply(attr_1: 'dirty')
      proto.should_not be(subject)
      proto.attributes.should == subject.attributes.merge(attr_1: 'dirty')
    end

    it 'returns self if no changes applied' do
      proto = subject.apply({})
      proto.should == subject
    end

    it 'returns self if attributes are changing to same values' do
      proto = subject.apply(attr_1: test_value)
      proto.should == subject
    end

    it 'adds changes to the copy it makes' do
      proto = subject.apply(attr_1: 'dirty')
      proto.attributes.should == attrs.merge(attr_1: 'dirty')
    end
  end

  describe '#changes' do
    it 'returns empty hash on new entity' do
      described_class.new_root.changes.should be_empty
    end

    it 'returns no attributes on "persisted" entity' do
      subject.changes.should be_empty
    end

    it 'returns incremental changes added by applying attributes' do
      subject.apply(attr_1: 'dirty').changes.should == { attr_1: 'dirty' }
    end
  end

  #describe '#attach_repo' do
  #  it 'attaches repo to entity that lacks it' do
  #    described_class.new_root.attach_repo(:foo).repo.should == :foo
  #  end

  #  it 'leaves repo of the parent alone as nil' do
  #    parent = described_class.new_root
  #    parent.apply(attr_1: test_value).attach_repo(:foo)
  #    parent.repo.should == nil
  #  end

  #  it 'raises error if entity already has repo' do
  #    expect {
  #      described_class.new_root(repo: :foo).attach_repo(:bar)
  #    }.to raise_error ORMivore::InvalidStateError
  #  end
  #end
end
