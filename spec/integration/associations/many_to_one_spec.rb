require 'spec_helper'

require 'adapters/memory_helpers'
require 'adapters/ar_helpers'
require 'adapters/sequel_helpers'
require 'adapters/redis_helpers'

shared_examples_for 'a working system' do
  let(:account_port) { Spec::Account::StoragePort.new(account_adapter) }
  # TODO entity_class should be just a first param for constructor right?
  let(:account_repo) { Spec::Account::Repo.new(Spec::Account::Entity, account_port) }

  let(:post_port) { Spec::Post::StoragePort.new(post_adapter) }
  # TODO entity_class should be just a first param for constructor right?
  let(:post_repo) { Spec::Post::Repo.new(Spec::Post::Entity, post_port) }

  describe '#author' do
    context 'when post is new' do
      let(:subject) { post_repo.create }

      it 'returns nil' do
        subject.author.should be nil
      end

      context 'when author is changed to non-persisted account' do
        it 'returns assigned author' do
          pending 'not working yet'
          author = account_repo.create
          subject.apply(author: author).author.should be(author)
        end
      end

      context 'when author is changed to persisted account' do
        it 'returns assigned author' do
          author = account_repo.create(firstname: 'foo')
          author = account_repo.persist(author)
          subject.apply(author: author).author.should be(author)
        end
      end
    end

    context 'when post is persisted without account' do
      let(:subject) {
        post_repo.persist(post_repo.create(title: 'foo'))
      }

      it 'returns nil' do
        subject.author.should be nil
      end

      context 'when author is changed to non-persisted account' do
        it 'returns assigned author' do
          pending 'not working yet'
          author = account_repo.create
          subject.apply(author: author).author.should be(author)
        end
      end

      context 'when author is changed to persisted account' do
        it 'returns assigned author' do
          author = account_repo.create(firstname: 'foo')
          author = account_repo.persist(author)
          subject.apply(author: author).author.should be(author)
        end
      end
    end
  end
end

describe 'an entity and its ecosystem' do
  before do
    Object.send(:remove_const, :Spec) if Object.const_defined?(:Spec)
    Spec = Module.new

    ORMivore::create_entity_skeleton(Spec, :account, port: true, repo: true) do
      attributes do
        string :firstname
      end
    end

    ORMivore::create_entity_skeleton(Spec, :post, port: true, repo: true) do
      attributes do
        string  :title
      end
      many_to_one :author, Spec::Account::Entity, fk: :account_id
    end
  end

  after do
    Object.send(:remove_const, :Spec) if Object.const_defined?(:Spec)
  end

  context 'with StorageMemoryAdapter' do
    include MemoryHelpers

    let(:account_adapter) { ORMivore::AnonymousFactory::create_memory_adapter.new }
    let(:post_adapter) { ORMivore::AnonymousFactory::create_memory_adapter.new }

    it_behaves_like 'a working system'
  end

  context 'with StorageArAdapter', :ar_db do
    include ArHelpers

    let(:account_adapter) { ORMivore::AnonymousFactory::create_ar_adapter('accounts').new }
    let(:post_adapter) { ORMivore::AnonymousFactory::create_ar_adapter('posts').new }

    it_behaves_like 'a working system'
  end

  context 'with StorageSequelAdapter', :sequel_db do
    include SequelHelpers

    let(:account_adapter) { ORMivore::AnonymousFactory::create_sequel_adapter('accounts').new }
    let(:post_adapter) { ORMivore::AnonymousFactory::create_sequel_adapter('posts').new }

    it_behaves_like 'a working system'
  end

  context 'with StoragePreparedSequelAdapter', :sequel_db do
    include SequelHelpers

    let(:account_adapter) { ORMivore::AnonymousFactory::create_prepared_sequel_adapter( 'accounts').new }
    let(:post_adapter) { ORMivore::AnonymousFactory::create_prepared_sequel_adapter('posts').new }

    it_behaves_like 'a working system'
  end

  context 'with StorageRedisAdapter', :redis_db do
    include RedisHelpers

    let(:account_adapter) { ORMivore::AnonymousFactory::create_redis_adapter('accounts').new }
    let(:post_adapter) { ORMivore::AnonymousFactory::create_redis_adapter('posts').new }

    it_behaves_like 'a working system'
  end
end
