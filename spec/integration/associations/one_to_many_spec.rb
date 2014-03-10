require 'spec_helper'

shared_examples_for 'a one-to-many association' do
  let(:family) { ORMivore::AnonymousFactory::create_repo_family.new }

  let(:account_port) { Spec::Account::StoragePort.new(account_adapter) }
  let(:post_port) { Spec::Post::StoragePort.new(post_adapter) }

  let(:account_repo) { session.repo.account }
  let(:post_repo) { session.repo.post }

  let(:session) { ORMivore::Session.new(family, associations) }

  let(:association) {
    session.association(subject, :posts)
  }

  before do
    Spec::Account::Repo.new(Spec::Account::Entity, account_port, family: family)
    Spec::Post::Repo.new(Spec::Post::Entity, post_port, family: family)
  end

  context 'for ephemeral account' do
    let(:subject) { account_repo.create(firstname: 'foo') }
    let(:post) { post_repo.create(title: 'foo') }

    it 'returns empty array' do
      association.values.should be_empty
    end

    context 'when post is set to ephemeral post' do
      it 'returns assigned post' do
        association.set(post)

        association.values.tap { |o|
          o.should eq([post.current])
          o.first.should be(post.current)
        }
      end

      it 'remembers assigned post after persisting' do
        association.set(post)

        account_repo.persist(subject)
        post_repo.persist(post.current)

        association.values.tap { |o|
          o.should eq([post.current])
          o.first.should be(post.current)
        }
      end
    end

    context 'when ephemeral post is added as post' do
      it 'returns assigned post' do
        association.add(post)

        association.values.tap { |o|
          o.should eq([post.current])
          o.first.should be(post.current)
        }
      end

      it 'remembers assigned post after persisting' do
        association.add(post)

        account_repo.persist(subject)
        post_repo.persist(post.current)

        association.values.tap { |o|
          o.should eq([post.current])
          o.first.should be(post.current)
        }
      end

      context 'when previously added post is removed' do
        it 'returns no posts' do
          association.add(post)
          association.remove(post.current)
          association.values.should be_empty
        end
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
        integer :account_id
      end
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

    it_behaves_like 'a one-to-many association'
  end

  context 'with StorageArAdapter', :secondary_adapter, :ar_db do
    let(:account_adapter) { ORMivore::AnonymousFactory::create_ar_adapter('accounts').new }
    let(:post_adapter) { ORMivore::AnonymousFactory::create_ar_adapter('posts').new }

    it_behaves_like 'a one-to-many association'
  end

  context 'with StorageSequelAdapter', :secondary_adapter, :sequel_db do
    let(:account_adapter) { ORMivore::AnonymousFactory::create_sequel_adapter('accounts').new }
    let(:post_adapter) { ORMivore::AnonymousFactory::create_sequel_adapter('posts').new }

    it_behaves_like 'a one-to-many association'
  end

  context 'with StoragePreparedSequelAdapter', :sql_adapter, :sequel_db do
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
