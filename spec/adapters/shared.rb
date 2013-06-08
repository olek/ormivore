shared_examples_for 'an adapter' do
  let(:test_value) { 'Foo' }

  let(:attrs_list) { [:id].concat(attrs.keys) }

  subject { adapter } # only 1 instance of adapter, please

  def create_entity(overrides = {})
    FactoryGirl.create(
      factory_name, factory_attrs.merge(adapter: subject, test_attr => test_value).merge(overrides)
    ).attributes.symbolize_keys
  end

  it 'responds to find' do
    subject.should respond_to(:find)
  end

  describe '#find' do
    context 'when conditions are empty' do
      it 'returns all available records' do
        subject.find({}, attrs_list).should be_empty
        create_entity
        subject.find({}, attrs_list).should have(1).record
        create_entity
        subject.find({}, attrs_list).should have(2).records
      end
    end

    context 'when conditions points to non-existing entity' do
      it 'returns empty array' do
        subject.find({id: 123456789}, attrs_list).should be_empty
      end
    end

    context 'when conditions point to existing entity' do
      it 'returns entity id' do
        entity = create_entity
        data = subject.find({id: entity[:id]}, attrs_list)
        data.first[:id].should == entity[:id]
      end

      it 'returns proper entity attrs' do
        entity = create_entity
        data = subject.find({id: entity[:id]}, attrs_list)
        data.should_not be_nil
        data.first[test_attr].should == entity[test_attr]
      end

      it 'returns only required entity attrs' do
        entity = create_entity
        data = subject.find({id: entity[:id]}, [test_attr]).first
        data.should == { test_attr => entity[test_attr] }
      end
    end

    context 'when conditions point to multiple entities' do
      before do
        create_entity(test_attr => 'v1')
        create_entity(test_attr => 'v2')
      end

      it 'returns array of attributes' do
        subject.find({}, attrs_list).should have(2).records
      end

      context 'when ordering criteria is provided' do
        it 'sorts records in ascending order' do
          subject.find(
            {}, attrs_list, order: { test_attr => :ascending }
          ).map { |o| o[test_attr] }.should == ['v1', 'v2']
        end

        it 'sorts records in descending order' do
          subject.find(
            {}, attrs_list, order: { test_attr => :descending }
          ).map { |o| o[test_attr] }.should == ['v2', 'v1']
        end

        it 'raises error if unknown ordering is provided' do
          expect {
            subject.find({}, attrs_list, order: { test_attr => :foo })
          }.to raise_error ORMivore::BadArgumentError
        end
      end
    end
  end

  describe '#create' do
    context 'when attempting to create record with id that is already present in database' do
      it 'raises error' do
        expect {
          subject.create(subject.create(attrs))
        }.to raise_error ORMivore::StorageError
      end
    end

    context 'when record does not have an id' do
      it 'returns back attributes including new id' do
        data = subject.create(attrs)
        data.should include(attrs)
        data[:id].should be_kind_of(Integer)
      end

      it 'inserts record in database' do
        data = subject.create(attrs)

        load_test_value(data[:id]).should == test_value
      end
    end
  end

  describe '#update' do
    context 'when record did not exist' do
      it 'returns 0 update count' do
        create_entity
        subject.update(attrs, id: 123).should == 0
      end
    end

    context 'when record existed' do
      it 'returns update count 1' do
        entity = create_entity

        subject.update(attrs, id: entity[:id]).should == 1
      end

      it 'updates record attributes' do
        entity = create_entity

        subject.update({test_attr => 'Bar'}, id: entity[:id])

        load_test_value(entity[:id]).should == 'Bar'
      end
    end

    context 'when 2 matching records existed' do
      it 'returns update count 2' do
        entity_ids = []
        entity_ids << create_entity[:id]
        entity_ids << create_entity[:id]

        subject.update(attrs, id: entity_ids).should == 2
      end
    end
  end
end
