require 'spec_helper'

shared_examples_for 'a one-to-many association' do
  let(:family) { ORMivore::AnonymousFactory::create_repo_family.new }

  let(:account_port) { Spec::Account::StoragePort.new(account_adapter) }
  let(:account_repo) { Spec::Account::Repo.new(Spec::Account::Entity, account_port, family: family) }

  let(:post_port) { Spec::Post::StoragePort.new(post_adapter) }
  let(:post_repo) { Spec::Post::Repo.new(Spec::Post::Entity, post_port, family: family) }

  context 'for ephemeral account' do
    let(:subject) { account_repo.create(firstname: 'foo') }
    let(:post) { post_repo.create(title: 'foo') }

    it 'returns empty array' do
      subject.articles.should be_empty
    end

    context 'when article is set to ephemeral post' do
      it 'returns assigned article' do
        subject.apply(articles: [post]).articles.tap { |o|
          o.should eq([post])
          o.first.should be(post)
        }
      end

      it 'remembers assigned article after persisting' do
        pending 'not working yet'

        account_repo.persist(
          subject.apply(articles: [post])
        ).articles.tap { |o|
          o.should eq([post])
          o.first.should be(post)
        }
      end
    end

    context 'when article is set to durable post' do
      let(:post) { post_repo.persist(super()) }

      it 'returns assigned article' do
        subject.apply(articles: [post]).tap { |o|
          o.articles.should eq([post])
          o.articles.first.should be(post)
        }
      end

      it 'remembers assigned article after persisting' do
        pending 'not working yet'

        account_repo.persist(
          subject.apply(articles: [post])
        ).articles.tap { |o|
          o.should eq([post])
          o.first.should be(post)
        }
      end
    end
  end
end

describe 'an association between post and its author' do
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

    Spec::Account::Entity.instance_eval do
      # TODO build a set of tests for the case when there is no inverse association
      # one_to_many :articles, Spec::Post::Entity, fk: :post_id
      one_to_many :articles, Spec::Post::Entity, inverse_of: :author
    end
  end

  after do
    Object.send(:remove_const, :Spec) if Object.const_defined?(:Spec)
  end

  context 'with StorageMemoryAdapter' do
    let(:account_adapter) { ORMivore::AnonymousFactory::create_memory_adapter.new }
    let(:post_adapter) { ORMivore::AnonymousFactory::create_memory_adapter.new }

    it_behaves_like 'a one-to-many association'
  end

  context 'with StorageArAdapter', :ar_db do
    let(:account_adapter) { ORMivore::AnonymousFactory::create_ar_adapter('accounts').new }
    let(:post_adapter) { ORMivore::AnonymousFactory::create_ar_adapter('posts').new }

    it_behaves_like 'a one-to-many association'
  end

  context 'with StorageSequelAdapter', :sequel_db do
    let(:account_adapter) { ORMivore::AnonymousFactory::create_sequel_adapter('accounts').new }
    let(:post_adapter) { ORMivore::AnonymousFactory::create_sequel_adapter('posts').new }

    it_behaves_like 'a one-to-many association'
  end

  context 'with StoragePreparedSequelAdapter', :sequel_db do
    let(:account_adapter) { ORMivore::AnonymousFactory::create_prepared_sequel_adapter( 'accounts').new }
    let(:post_adapter) { ORMivore::AnonymousFactory::create_prepared_sequel_adapter('posts').new }

    it_behaves_like 'a one-to-many association'
  end

=begin should we test associations with redis? it lacks generic find interface...
  context 'with StorageRedisAdapter', :redis_db do
    let(:account_adapter) { ORMivore::AnonymousFactory::create_redis_adapter('accounts').new }
    let(:post_adapter) { ORMivore::AnonymousFactory::create_redis_adapter('posts').new }

    it_behaves_like 'a one-to-many association'
  end
=end
end
