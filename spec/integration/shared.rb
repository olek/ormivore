shared_examples_for 'an integrated repo' do
  let(:test_value) { 'Foo' }

  subject { described_class.new(port) }

  describe '#find_by_id' do
    it 'loads entity if found' do
      account = create_entity
      subject.find_by_id(account[:id]).public_send(test_attr).should == test_value
    end

    it 'raises error if entity is not found' do
      expect {
        subject.find_by_id(123)
      }.to raise_error ORMivore::RecordNotFound
    end

    context 'in quiet mode' do
      it 'returns nil if entity is not found' do
        subject.find_by_id(123, quiet: true).should be_nil
      end
    end
  end

  describe '#persist' do
    context 'when entity is new' do
      it 'creates and returns new entity' do
        entity = entity_class.new(attrs)
        saved_entity = subject.persist(entity)
        saved_entity.should_not be_nil
        saved_entity.attributes.should == attrs
        saved_entity.id.should be_kind_of(Integer)

        load_test_value(saved_entity.id).should == attrs[test_attr]
      end
    end

    context 'when entity is not new' do
      let(:existing_entity_id) {
        create_entity[:id]
      }

      it 'updates record in database' do
        entity = entity_class.new({}, existing_entity_id, attrs)
        saved_entity = subject.persist(entity)
        saved_entity.should_not be_nil
        saved_entity.attributes.should == attrs
        saved_entity.id.should == existing_entity_id

        load_test_value(saved_entity.id).should == attrs[test_attr]
      end
    end
  end
end
