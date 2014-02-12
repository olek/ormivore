require 'spec_helper'

shared_examples_for 'a many-to-one association' do
  let(:family) { ORMivore::AnonymousFactory::create_repo_family.new }

  let(:account_port) { Spec::Account::StoragePort.new(account_adapter) }
  let(:account_repo) { Spec::Account::Repo.new(Spec::Account::Entity, account_port, family: family) }

  let(:post_port) { Spec::Post::StoragePort.new(post_adapter) }
  let(:post_repo) { Spec::Post::Repo.new(Spec::Post::Entity, post_port, family: family) }

  context 'for ephemeral post' do
    let(:subject) { post_repo.create(title: 'foo') }
    let(:author) { account_repo.create(firstname: 'foo') }

    it 'returns nil' do
      subject.author.should be nil
    end

    context 'when author is set to ephemeral account' do
      it 'returns assigned author' do
        subject.apply(author: author).author.should be(author)
      end

      it 'remembers assigned author after persisting' do
        pending 'not working yet'

        post_repo.persist(subject.apply(author: author)).
          author.should be(author)
      end
    end

    context 'when author is set to durable account' do
      it 'returns assigned author' do
        other_author = account_repo.persist(author)
        subject.apply(author: other_author).author.should be(other_author)
      end
    end
  end

  context 'for durable post without an account' do
    let(:subject) { post_repo.persist(post_repo.create(title: 'foo')) }
    let(:author) { account_repo.create(firstname: 'foo') }

    it 'returns nil' do
      subject.author.should be nil
    end

    context 'when author is set to ephemeral account' do
      it 'returns assigned author' do
        subject.apply(author: author).author.should be(author)
      end

      it 'remembers assigned ephemeral author after persisting post' do
        pending 'not working yet'

        post_repo.persist(subject.apply(author: author)).author.should be(author)
      end
    end

    context 'when author changed to ephemeral account twice' do
      it 'returns latest ephemeral author' do
        post = subject.apply(author: author)
        revised_author = author.apply(firstname: 'bar')
        post.apply(author: revised_author).author.should be(revised_author)
      end

      it 'remembers assigned ephemeral author after persisting' do
        pending 'not working yet'

        post = subject.apply(author: author)
        revised_author = author.apply(firstname: 'bar')
        post_repo.persist(post.apply(author: revised_author)).author.should eql(revised_author)
      end
    end

    context 'when author is set to durable account' do
      it 'returns assigned author' do
        other_author = account_repo.persist(author)
        subject.apply(author: other_author).author.should be(other_author)
      end
    end
  end

  context 'for durable post with author' do
    let(:author) { account_repo.persist(account_repo.create(firstname: 'foo')) }

    let(:subject) { post_repo.persist(post_repo.create(title: 'foo', author: author)) }

    it 'returns previously assigned durable author' do
      # NOTE with identity map it should be 'be' identity check, not equivalence
      subject.author.should eq author
    end

    context 'when author is changed to ephemeral account' do
      it 'returns assigned author' do
        other_author = account_repo.create
        subject.apply(author: other_author).author.should be(other_author)
      end

      it 'remembers assigned ephemeral author after persisting' do
        pending 'not working yet'

        other_author = account_repo.create(firstname: 'foo')
        post_repo.persist(subject.apply(author: other_author)).
          author.should eq(other_author)
      end
    end

    context 'when author changed to revised version of itself' do
      it 'returns revised author' do
        revised_author = author.apply(firstname: 'bar')
        subject.apply(author: revised_author).author.should be(revised_author)
      end

      it 'remembers assigned revised author after persisting' do
        pending 'not working yet'

        revised_author = author.apply(firstname: 'bar')
        post_repo.persist(subject.apply(author: revised_author)).author.should eql(revised_author)
      end
    end

    context 'when author changed to revised version of itself twice' do
      it 'returns revised author' do
        revised_author = author.apply(firstname: 'bar')
        post = subject.apply(author: revised_author)
        revised_author = revised_author.apply(firstname: 'baz')
        post.apply(author: revised_author).author.should be(revised_author)
      end

      it 'remembers assigned revised author after persisting' do
        pending 'not working yet'

        revised_author = author.apply(firstname: 'bar')
        post = subject.apply(author: revised_author)
        revised_author = revised_author.apply(firstname: 'baz')
        post_repo.persist(post.apply(author: revised_author)).author.should eql(revised_author)
      end
    end

    context 'when author is changed to another durable account' do
      it 'returns assigned author' do
        other_author = account_repo.create(firstname: 'bar')
        other_author = account_repo.persist(other_author)
        subject.apply(author: other_author).author.should be(other_author)
      end

      it 'remembers assigned author after persisting' do
        other_author = account_repo.create(firstname: 'bar')
        other_author = account_repo.persist(other_author)
        post_repo.persist(subject.apply(author: other_author)).
          author.should eq(other_author)
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
  end

  after do
    Object.send(:remove_const, :Spec) if Object.const_defined?(:Spec)
  end

  context 'with StorageMemoryAdapter' do
    let(:account_adapter) { ORMivore::AnonymousFactory::create_memory_adapter.new }
    let(:post_adapter) { ORMivore::AnonymousFactory::create_memory_adapter.new }

    it_behaves_like 'a many-to-one association'
  end

  context 'with StorageArAdapter', :ar_db do
    let(:account_adapter) { ORMivore::AnonymousFactory::create_ar_adapter('accounts').new }
    let(:post_adapter) { ORMivore::AnonymousFactory::create_ar_adapter('posts').new }

    it_behaves_like 'a many-to-one association'
  end

  context 'with StorageSequelAdapter', :sequel_db do
    let(:account_adapter) { ORMivore::AnonymousFactory::create_sequel_adapter('accounts').new }
    let(:post_adapter) { ORMivore::AnonymousFactory::create_sequel_adapter('posts').new }

    it_behaves_like 'a many-to-one association'
  end

  context 'with StoragePreparedSequelAdapter', :sequel_db do
    let(:account_adapter) { ORMivore::AnonymousFactory::create_prepared_sequel_adapter( 'accounts').new }
    let(:post_adapter) { ORMivore::AnonymousFactory::create_prepared_sequel_adapter('posts').new }

    it_behaves_like 'a many-to-one association'
  end

  context 'with StorageRedisAdapter', :redis_db do
    let(:account_adapter) { ORMivore::AnonymousFactory::create_redis_adapter('accounts').new }
    let(:post_adapter) { ORMivore::AnonymousFactory::create_redis_adapter('posts').new }

    it_behaves_like 'a many-to-one association'
  end
end
