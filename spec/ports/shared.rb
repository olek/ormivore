shared_examples_for 'a port' do
  let(:adapter) {
    double('adapter')
  }

  subject { described_class.new(adapter) }

  describe '#find' do
    it 'delegates to adapter' do
      adapter.should_receive(:find).with(:foo, quiet: true).and_return(:bar)
      subject.find(:foo, quiet: true).should == :bar
    end

    it 'assumes empty options' do
      adapter.should_receive(:find).with(:foo, {}).and_return(:bar)
      subject.find(:foo).should == :bar
    end

    it 'allows empty options' do
      adapter.should_receive(:find).with(:foo, {}).and_return(:bar)
      subject.find(:foo, {}).should == :bar
    end

    it 'raises error on invalid options' do
      expect {
        subject.find(:foo, foo: 'bar')
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
