require 'spec_helper'

describe 'a repo' do
  let(:entity) {
    double('entity', id: nil, changes: { foo: 'bar' }, association_adjustments: {},
      foreign_keys: {}, foreign_key_changes: {},
      validate: nil, dismissed?: false, dismiss: nil)
  }

  let(:new_entity) {
    double('new_entity', id: 123)
  }

  let(:attributes_list) { [:id, :foo] }

  let(:entity_class) {
    double('entity_class', new: new_entity, name: 'FakeEntity',
      attributes_list: [:foo], association_definitions: {},
      foreign_key_association_definitions: {}, foreign_keys: [])
  }

  let(:port) {
    double('port')
  }

  let(:described_class) {
    ORMivore::AnonymousFactory::create_repo
  }

  subject { described_class.new(entity_class, port) }

  describe '#find_by_id' do
    it 'delegates to port' do
      port.should_receive(:find_by_id).with(:foo, attributes_list).and_return(a: 'b')
      subject.find_by_id(:foo)
    end

    it 'creates and returns new entity' do
      port.stub(:find_by_id).with(123, attributes_list).and_return(foo: 'bar')
      subject.find_by_id(123).should == new_entity
    end

    it 'creates new entity with proper attributes' do
      port.stub(:find_by_id).with(:foo, attributes_list).and_return(id: 123, foo: 'bar')
      entity_class.should_receive(:new).with(attributes: {foo: 'bar'}, id: 123, repo: subject)
      subject.find_by_id(:foo)
    end

    context 'when port raises RecordNotFound' do
      it 'should re-raise error' do
        expect {
          port.should_receive(:find_by_id).with(:foo, attributes_list).and_raise(ORMivore::RecordNotFound)
          subject.find_by_id(:foo)
        }.to raise_error ORMivore::RecordNotFound
      end
    end
  end

  # TODO now add integration test for it
  describe '#find_all_by_id_as_hash' do
    it 'delegates to port' do
      port.should_receive(:find_all_by_id).with([123, 124], attributes_list).and_return([{}, {}])
      subject.find_all_by_id_as_hash([123, 124], quiet: true)
    end

    it 'creates and returns new entity' do
      port.stub(:find_all_by_id).with(anything, anything).and_return([{ id: 123 }, {}])
      subject.find_all_by_id_as_hash([123, 124], quiet: true).should == { new_entity.id => new_entity }
    end

    it 'creates new entity with proper attributes' do
      port.stub(:find_all_by_id).with(anything, anything).and_return([{ id: 123, a: 'b' }, { id: 124, c: 'd' }])
      entity_class.should_receive(:new).with(attributes: {a: 'b'}, id: 123, repo: subject)
      entity_class.should_receive(:new).with(attributes: {c: 'd'}, id: 124, repo: subject)
      subject.find_all_by_id_as_hash([123, 124], quiet: true)
    end

    context 'when entity is not found by id' do
      context 'when quiet option is set to false (default)' do
        it 'raises error' do
          expect {
            port.should_receive(:find_all_by_id).with(anything, anything).and_return([])
            subject.find_all_by_id_as_hash([123])
          }.to raise_error ORMivore::RecordNotFound
        end
      end
    end

    context 'when block is provided' do
      it 'uses block to convert array of objects to array of ids' do
        port.should_receive(:find_all_by_id).with([123, 124], attributes_list).and_return([{}, {}])
        subject.find_all_by_id_as_hash(['321', '421'], quiet: true) { |o| Integer(o.reverse) }
      end

      it 'returns map of input objects to entities' do
        port.stub(:find_all_by_id).with(anything, anything).and_return([{ id: 123, a: 'b' }, { id: 124, c: 'd' }])
        entity_class.should_receive(:new).with(attributes: {a: 'b'}, id: 123, repo: subject).and_return(:foo)
        entity_class.should_receive(:new).with(attributes: {c: 'd'}, id: 124, repo: subject).and_return(:bar)
        result = subject.find_all_by_id_as_hash(['321', '421'], quiet: true) { |o| Integer(o.reverse) }
        result.should have(2).entities
        result['321'].should == :foo
        result['421'].should == :bar
      end
    end
  end

  describe '#persist' do
    context 'when entity is new' do
      it 'delegates to port.create' do
        port.should_receive(:create).with(foo: 'bar')
        subject.persist(entity)
      end

      it 'creates and returns new entity' do
        port.stub(:create).with(foo: 'bar').and_return(id: 123, foo: 'bar')
        subject.persist(entity).should == new_entity
      end
    end

    context 'when entity is not new' do
      before do
        entity.stub(:id).and_return(123)
        port.stub(:update_one).with(123, foo: 'bar').and_return(1)
      end

      it 'delegates changes to port.update_one' do
        entity.stub(:attributes).and_return(a: 'b')
        # entity.should_receive(:changed?).and_return(true)
        entity.should_receive(:changes).and_return(foo: 'changed')
        port.should_receive(:update_one).with(123, foo: 'changed').and_return(1)
        subject.persist(entity)
      end

      it 'creates new entity with all attributes' do
        entity.should_receive(:attributes).and_return(a: 'b')
        # entity.should_receive(:changed?).and_return(true)
        entity_class.should_receive(:new).with(attributes: {a: 'b'}, id: entity.id, repo: subject).and_return(:baz)
        subject.persist(entity).should == :baz
      end

      it 'raises error if record was not updated' do
        # entity.should_receive(:changed?).and_return(true)
        port.should_receive(:update_one).with(123, foo: 'bar').and_return(0)
        expect {
          subject.persist(entity)
        }.to raise_error ORMivore::StorageError
      end

      it 'raises error if more than one record was updated' do
        # entity.should_receive(:changed?).and_return(true)
        port.should_receive(:update_one).with(123, foo: 'bar').and_return(2)
        expect {
          subject.persist(entity)
        }.to raise_error ORMivore::StorageError
      end
    end
  end

  describe '#delete' do
    context 'when entity is new' do
      it 'raises an error' do
        expect {
          subject.delete(entity)
        }.to raise_error ORMivore::StorageError
      end
    end

    context 'when entity is not new' do
      before do
        entity.stub(:id).and_return(123)
        port.stub(:delete_one).with(123).and_return(1)
      end

      it 'delegates to port.delete_one' do
        port.should_receive(:delete_one).with(123).and_return(1)
        subject.delete(entity)
      end

      it 'returns true if record was deleted' do
        subject.delete(entity).should == true
      end

      it 'raises error if record was not deleted' do
        port.should_receive(:delete_one).with(123).and_return(0)
        expect {
          subject.delete(entity)
        }.to raise_error ORMivore::StorageError
      end

      it 'raises error if more than one record was deleted' do
        port.should_receive(:delete_one).with(123).and_return(2)
        expect {
          subject.delete(entity)
        }.to raise_error ORMivore::StorageError
      end
    end
  end
end
