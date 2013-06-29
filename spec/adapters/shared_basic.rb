shared_examples_for 'a basic adapter' do
  let(:test_value) { 'Foo' }

  let(:attrs_list) { [:id].concat(attrs.keys) }

  subject { adapter } # only 1 instance of adapter, please

  def create_entity(overrides = {})
    FactoryGirl.create(
      factory_name, factory_attrs.merge(adapter: subject, test_attr => test_value).merge(overrides)
    ).attributes.symbolize_keys
  end

  it 'responds to find_by_id' do
    subject.should respond_to(:find_by_id)
  end

  describe '#find_by_id' do
    context 'when id points to non-existing entity' do
      # TODO returning array from find_by_id is madness, refactor it
      it 'returns empty array' do
        subject.find_by_id(123456789, attrs_list).should be_empty
      end
    end

    context 'when id points to existing entity' do
      it 'returns entity with id' do
        entity = create_entity
        data = subject.find_by_id(entity[:id], attrs_list)
        data.first[:id].should == entity[:id]
      end

      it 'returns entity with proper attrs' do
        entity = create_entity
        data = subject.find_by_id(entity[:id], attrs_list)
        data.should_not be_nil
        data.first[test_attr].should == entity[test_attr]
      end

      it 'returns only required entity attrs' do
        entity = create_entity
        data = subject.find_by_id(entity[:id], [test_attr]).first
        data.should == { test_attr => entity[test_attr] }
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

  describe '#update_one' do
    context 'when record did not exist' do
      it 'returns 0 update count' do
        create_entity
        subject.update_one(123, attrs).should == 0
      end
    end

    context 'when record existed' do
      it 'returns update count 1' do
        entity = create_entity

        subject.update_one(entity[:id], attrs).should == 1
      end

      it 'updates record attributes' do
        entity = create_entity

        subject.update_one(entity[:id], test_attr => 'Bar')

        load_test_value(entity[:id]).should == 'Bar'
      end
    end
  end
end
