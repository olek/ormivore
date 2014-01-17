require_relative 'shared_basic'

shared_examples_for 'an expanded port' do
  let(:adapter) {
    double('adapter')
  }

  subject { described_class.new(adapter) }

  include_examples 'a basic port'

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

  describe '#update_all' do
    it 'delegates to adapter' do
      adapter.should_receive(:update_all).with(:foo, a: 'b').and_return(:bar)
      subject.update_all(:foo, a: 'b').should == :bar
    end
  end

  describe '#delete_all' do
    it 'delegates to adapter' do
      adapter.should_receive(:delete_all).with(:foo).and_return(:bar)
      subject.delete_all(:foo).should == :bar
    end
  end
end
