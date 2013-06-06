shared_examples_for 'a repo' do
  let(:entity) {
    double('entity', id: nil, changes: { foo: 'bar' })
  }

  let(:entity_class) {
    double('entity_class', new: :new_entity)
  }

  let(:port) {
    double('port')
  }

  subject { described_class.new(port, entity_class) }

  describe '#find_by_id' do
    it 'delegates to port' do
      port.should_receive(:find).with({ id: :foo }, {})
      subject.find_by_id(:foo)
    end

    it 'creates and returns new entity' do
      port.stub(:find).with({ id: 123 }, {}).and_return(foo: 'bar')
      subject.find_by_id(123).should == :new_entity
    end

    it 'creates new entity with proper attributes' do
      port.stub(:find).with({ id: :foo }, {}).and_return(id: 123, foo: 'bar')
      entity_class.should_receive(:new).with({foo: 'bar'}, 123)
      subject.find_by_id(:foo)
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
        port.stub(:update).with({ foo: 'bar' }, id: 123).and_return(1)
      end

      it 'delegates changes to port.update' do
        entity.stub(:attributes).and_return(a: 'b')
        entity.stub(:create).with({a: 'b'}, entity.id).and_return(:baz)
        port.should_receive(:update).with({ foo: 'bar' }, id: 123).and_return(1)
        subject.persist(entity)
      end

      it 'creates new entity with all attributes' do
        entity.should_receive(:attributes).and_return(a: 'b')
        entity.should_receive(:create).with({a: 'b'}, entity.id).and_return(:baz)
        subject.persist(entity).should == :baz
      end

      it 'raises error if record was not updated' do
        port.should_receive(:update).with({ foo: 'bar' }, id: 123).and_return(0)
        expect {
          subject.persist(entity)
        }.to raise_error ORMivore::StorageError
      end

      it 'raises error if more than one record was updated' do
        port.should_receive(:update).with({ foo: 'bar' }, id: 123).and_return(2)
        expect {
          subject.persist(entity)
        }.to raise_error ORMivore::StorageError
      end
    end
  end
end
