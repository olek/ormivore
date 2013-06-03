shared_examples_for 'a port' do
  let(:adapter) {
    double('adapter')
  }

  subject { described_class.new(adapter) }

  describe '#find' do
    it 'delegates to adapter' do
      adapter.should_receive(:find).with(:foo, a: 'b').and_return(:bar)
      subject.find(:foo, a: 'b').should == :bar
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
