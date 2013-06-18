shared_examples_for 'a port' do
  let(:adapter) {
    double('adapter')
  }

  subject { described_class.new(adapter) }

  describe '#find' do
    it 'delegates to adapter' do
      adapter.should_receive(:find).with(:foo, :list, {}).and_return(:bar)
      subject.find(:foo, :list).should == :bar
    end

    it 'assumes empty options' do
      adapter.should_receive(:find).with(:foo, :list, {}).and_return(:bar)
      subject.find(:foo, :list).should == :bar
    end

    it 'allows empty options' do
      adapter.should_receive(:find).with(:foo, :list, {}).and_return(:baz)
      subject.find(:foo, :list, {}).should == :baz
    end

    it 'allows order option' do
      adapter.should_receive(:find).with(:foo, :list, { order: {}}).and_return(:baz)
      subject.find(:foo, :list, { order: {} }).should == :baz
    end

    it 'allows limit option' do
      adapter.should_receive(:find).with(:foo, :list, { limit: 1}).and_return(:baz)
      subject.find(:foo, :list, { limit: 1 }).should == :baz
    end

    it 'allows offset option' do
      adapter.should_receive(:find).with(:foo, :list, { offset: 1}).and_return(:baz)
      subject.find(:foo, :list, { offset: 1 }).should == :baz
    end

    it 'raises error on invalid options' do
      expect {
        subject.find(:foo, :list, foo: 'bar')
      }.to raise_error ORMivore::BadArgumentError
    end

    it 'raises error if ordering on unknown key' do
      expect {
        subject.find({}, [:foo], order: { :bar => :ascending })
      }.to raise_error ORMivore::BadArgumentError
    end
  end

  describe '#create' do
    it 'delegates to adapter' do
      adapter.should_receive(:create).with(:foo).and_return(:bar)
      subject.create(:foo).should == :bar
    end
  end

  describe '#update' do
    it 'delegates to adapter' do
      adapter.should_receive(:update).with(:foo, a: 'b').and_return(:bar)
      subject.update(:foo, a: 'b').should == :bar
    end
  end
end
