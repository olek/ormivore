shared_examples_for 'a basic port' do
  let(:adapter) {
    double('adapter')
  }

  subject { described_class.new(adapter) }

  describe '#find_by_id' do
    it 'delegates to adapter' do
      adapter.should_receive(:find_by_id).with(:foo, :list).and_return(:bar)
      subject.find_by_id(:foo, :list).should == :bar
    end
  end

  describe '#create' do
    it 'delegates to adapter' do
      adapter.should_receive(:create).with(:foo).and_return(:bar)
      subject.create(:foo).should == :bar
    end
  end

  describe '#update_one' do
    it 'delegates to adapter' do
      adapter.should_receive(:update_one).with(:foo, a: 'b').and_return(:bar)
      subject.update_one(:foo, a: 'b').should == :bar
    end
  end
end
