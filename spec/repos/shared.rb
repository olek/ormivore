shared_examples_for 'a repo' do
  let(:entity) {
    double('entity', id: nil, changes: { foo: 'bar' })
  }

  let(:attributes_list) { [:id, :foo] }

  let(:entity_class) {
    double('entity_class', construct: :new_entity, name: 'FakeEntity', attributes_list: [:foo])
  }

  let(:port) {
    double('port')
  }

  subject { described_class.new(port, entity_class) }

  describe '#find_by_id' do
    it 'delegates to port' do
      port.should_receive(:find_by_id).with(:foo, attributes_list).and_return(a: 'b')
      subject.find_by_id(:foo)
    end

    it 'creates and returns new entity' do
      port.stub(:find_by_id).with(123, attributes_list).and_return(foo: 'bar')
      subject.find_by_id(123).should == :new_entity
    end

    it 'creates new entity with proper attributes' do
      port.stub(:find_by_id).with(:foo, attributes_list).and_return(id: 123, foo: 'bar')
      entity_class.should_receive(:construct).with({foo: 'bar'}, 123)
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

  describe '#persist' do
    context 'when entity is new' do
      it 'delegates to port.create' do
        port.should_receive(:create).with(foo: 'bar')
        subject.persist(entity)
      end

      it 'creates and returns new entity' do
        port.stub(:create).with(foo: 'bar').and_return(id: 123, foo: 'bar')
        subject.persist(entity).should == :new_entity
      end
    end

    context 'when entity is not new' do
      before do
        entity.stub(:id).and_return(123)
        port.stub(:update_one).with(123, foo: 'bar').and_return(1)
      end

      it 'delegates changes to port.update_one' do
        entity.stub(:attributes).and_return(a: 'b')
        entity.should_receive(:changes).and_return(foo: 'changed')
        port.should_receive(:update_one).with(123, foo: 'changed').and_return(1)
        subject.persist(entity)
      end

      it 'creates new entity with all attributes' do
        entity.should_receive(:attributes).and_return(a: 'b')
        entity_class.should_receive(:construct).with({a: 'b'}, entity.id).and_return(:baz)
        subject.persist(entity).should == :baz
      end

      it 'raises error if record was not updated' do
        port.should_receive(:update_one).with(123, foo: 'bar').and_return(0)
        expect {
          subject.persist(entity)
        }.to raise_error ORMivore::StorageError
      end

      it 'raises error if more than one record was updated' do
        port.should_receive(:update_one).with(123, foo: 'bar').and_return(2)
        expect {
          subject.persist(entity)
        }.to raise_error ORMivore::StorageError
      end
    end
  end
end
