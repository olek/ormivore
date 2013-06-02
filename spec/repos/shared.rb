shared_examples_for 'a repo' do
  let(:entity) {
    # TODO .new? is too similar to .new, confusing, fix the code
    double('entity', new?: true, id: nil, to_hash: { foo: 'bar' })
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
        entity.stub(:new?).and_return(false)
        entity.stub(:id).and_return(123)
        port.stub(:update).with({ foo: 'bar' }, id: 123).and_return(1)
      end

      it 'delegates to port.update' do
        port.should_receive(:update).with({ foo: 'bar' }, id: 123).and_return(1)
        subject.persist(entity)
      end

      # TODO really? the same entity? For now, yes, but not for long -
      # 'dirty' flags will need to be updated
      it 'returns same entity' do
        subject.persist(entity).should == entity
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
