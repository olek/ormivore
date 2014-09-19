require 'spec_helper'

shared_examples_for 'a many-to-one association' do
  let(:family) { ORMivore::AnonymousFactory::create_repo_family.new }

  let(:account_port) { Spec::Account::StoragePort.new(account_adapter) }
  let(:post_port) { Spec::Post::StoragePort.new(post_adapter) }

  let(:account_repo) { session.repo.account }
  let(:post_repo) { session.repo.post }

  let(:session) { ORMivore::Session.new(family, associations) }

  let(:association) {
    session.association(subject.current, :account)
  }

  before do
    Spec::Account::Repo.new(Spec::Account::Entity, account_port, family: family)
    Spec::Post::Repo.new(Spec::Post::Entity, post_port, family: family)
  end

  context 'for ephemeral post' do
    let(:subject) { post_repo.create(title: 'foo') }
    let(:account) { account_repo.create(firstname: 'foo') }

    it 'returns nil' do
      association.value.should be nil
    end

    context 'when account is set to ephemeral account' do
      it 'returns assigned account' do
        association.set(account)
        association.value.should be(account)
      end

      it 'remembers assigned account after persisting' do
        association.set(account)
        post_repo.persist(subject.current)
        association.value.should be(account)
      end
    end

    context 'when account is set to durable account' do
      it 'returns assigned account' do
        other_account = account_repo.persist(account)
        other_account.should be_durable
        association.set(other_account)
        association.value.should be(other_account)
      end
    end

    context 'when account is set to durable account id' do
      it 'returns assigned account' do
        other_account = account_repo.persist(account)
        other_account.should be_durable
        subject.apply(account_id: other_account.identity)
        association.value.should be(other_account)
      end
    end
  end
end

describe 'an association between post and its account' do
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
        integer :account_id
      end

      optional :account_id
    end
  end

  let(:associations) {
    Class.new do
      extend ORMivore::Association::AssociationDefinitions

      association do
        from Spec::Post::Entity
        to Spec::Account::Entity
        as :account
        reverse_as :many, :posts
      end
    end
  }

  after do
    Object.send(:remove_const, :Spec) if Object.const_defined?(:Spec)
  end

  context 'with StorageMemoryAdapter', :memory_adapter do
    let(:account_adapter) { ORMivore::AnonymousFactory::create_memory_adapter.new }
    let(:post_adapter) { ORMivore::AnonymousFactory::create_memory_adapter.new }

    it_behaves_like 'a many-to-one association'
  end

  context 'with StorageArAdapter', :secondary_adapter, :ar_db do
    let(:account_adapter) { ORMivore::AnonymousFactory::create_ar_adapter('accounts').new }
    let(:post_adapter) { ORMivore::AnonymousFactory::create_ar_adapter('posts').new }

    it_behaves_like 'a many-to-one association'
  end

  context 'with StorageSequelAdapter', :secondary_adapter, :sequel_db do
    let(:account_adapter) { ORMivore::AnonymousFactory::create_sequel_adapter('accounts').new }
    let(:post_adapter) { ORMivore::AnonymousFactory::create_sequel_adapter('posts').new }

    it_behaves_like 'a many-to-one association'
  end

  context 'with StoragePreparedSequelAdapter', :sql_adapter, :sequel_db do
    let(:account_adapter) { ORMivore::AnonymousFactory::create_prepared_sequel_adapter( 'accounts').new }
    let(:post_adapter) { ORMivore::AnonymousFactory::create_prepared_sequel_adapter('posts').new }

    it_behaves_like 'a many-to-one association'
  end

  context 'with StorageRedisAdapter', :secondary_adapter, :redis_db do
    let(:account_adapter) { ORMivore::AnonymousFactory::create_redis_adapter('accounts').new }
    let(:post_adapter) { ORMivore::AnonymousFactory::create_redis_adapter('posts').new }

    it_behaves_like 'a many-to-one association'
  end
end
