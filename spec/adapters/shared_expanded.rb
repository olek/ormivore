require_relative 'shared_basic'

shared_examples_for 'an expanded adapter' do
  let(:test_value) { 'Foo' }

  let(:attrs_list) { [:id].concat(attrs.keys) }

  subject { adapter } # only 1 instance of adapter, please

  def create_entity(overrides = {})
    FactoryGirl.create(
      factory_name, factory_attrs.merge(adapter: subject, test_attr => test_value).merge(overrides)
    ).attributes.symbolize_keys
  end

  include_examples 'a basic adapter'

  it 'responds to find' do
    subject.should respond_to(:find)
  end

  describe '#count' do
    context 'when conditions are empty' do
      it 'returns count of all available records' do
        subject.count({}).should be_zero
        create_entity
        subject.count({}).should eq(1)
        create_entity
        subject.count({}).should eq(2)
      end
    end

    context 'when conditions points to non-existing entity' do
      it 'returns zero' do
        subject.count({id: 123456789}).should be_zero
      end
    end

    context 'when conditions point to existing entity' do
      it 'returns one' do
        entity = create_entity
        subject.count({id: entity[:id]}).should eq(1)
      end
    end

    context 'when conditions point to multiple entities' do
      before do
        create_entity(test_attr => 'v1')
        create_entity(test_attr => 'v2')
      end

      it 'returns number of entities' do
        subject.count({}).should eq(2)
      end
    end
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

      context 'when limit option is provided' do
        it 'limits number of records returned' do
          subject.find(
            {}, attrs_list, limit: 1
          ).should have(1).record
        end

        it 'selects records in their order' do
          subject.find(
            {}, attrs_list, order: { test_attr => :ascending }, limit: 1
          ).map { |o| o[test_attr] }.should == ['v1']

          subject.find(
            {}, attrs_list, order: { test_attr => :descending }, limit: 1
          ).map { |o| o[test_attr] }.should == ['v2']
        end

        it 'raises error if non-integer limit is provided' do
          expect {
            subject.find({}, attrs_list, limit: 'foo')
          }.to raise_error ArgumentError
        end
      end

      context 'when offset option is provided' do
        it 'limits number of records returned' do
          subject.find(
            {}, attrs_list, offset: 1, limit: 999
          ).should have(1).record
        end

        it 'offsets records in their order' do
          subject.find(
            {}, attrs_list, order: { test_attr => :ascending }, offset: 1, limit: 999
          ).map { |o| o[test_attr] }.should == ['v2']

          subject.find(
            {}, attrs_list, order: { test_attr => :descending }, offset: 1, limit: 999
          ).map { |o| o[test_attr] }.should == ['v1']
        end

        it 'raises error if non-integer offset is provided' do
          expect {
            subject.find({}, attrs_list, offset: 'foo', limit: 999)
          }.to raise_error ArgumentError
        end
      end
    end
  end

  describe '#update_all' do
    context 'when record did not exist' do
      it 'returns 0 update count' do
        create_entity
        subject.update_all({ id: 123 }, attrs).should == 0
      end
    end

    context 'when record existed' do
      it 'returns update count 1' do
        entity = create_entity

        subject.update_all({ id: entity[:id] }, attrs).should == 1
      end

      it 'updates record attributes' do
        entity = create_entity

        subject.update_all({ id: entity[:id] }, test_attr => 'Bar')

        load_test_value(entity[:id]).should == 'Bar'
      end
    end

    context 'when 2 matching records existed' do
      it 'returns update count 2' do
        entity_ids = []
        entity_ids << create_entity[:id]
        entity_ids << create_entity[:id]

        subject.update_all({ id: entity_ids }, attrs).should == 2
      end
    end
  end

  describe '#delete_all' do
    context 'when record did not exist' do
      it 'returns 0 delete count' do
        create_entity
        subject.delete_all({ id: 123 }).should == 0
      end
    end

    context 'when record existed' do
      it 'returns delete count 1' do
        entity = create_entity

        subject.delete_all({ id: entity[:id] }).should == 1
      end

      it 'deletes record attributes' do
        entity = create_entity

        subject.delete_all({ id: entity[:id] })

        load_test_value(entity[:id]).should == nil
      end
    end

    context 'when 2 matching records existed' do
      it 'returns delete count 2' do
        entity_ids = []
        entity_ids << create_entity[:id]
        entity_ids << create_entity[:id]

        subject.delete_all({ id: entity_ids }).should == 2
      end
    end
  end
end
