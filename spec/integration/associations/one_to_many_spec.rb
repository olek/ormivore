require 'spec_helper'

shared_examples_for 'a one-to-many association' do
  let(:family) { ORMivore::AnonymousFactory::create_repo_family.new }

  let(:account_port) { Spec::Account::StoragePort.new(account_adapter) }
  let(:post_port) { Spec::Post::StoragePort.new(post_adapter) }

  let(:account_repo) { session.repo.account }
  let(:post_repo) { session.repo.post }

  let(:session) { ORMivore::Session.new(family) }

  before do
    Spec::Account::Repo.new(Spec::Account::Entity, account_port, family: family)
    Spec::Post::Repo.new(Spec::Post::Entity, post_port, family: family)
  end

=begin
  context 'for ephemeral account' do
    let(:subject) { account_repo.create(firstname: 'foo') }
    let(:post) { post_repo.create(title: 'foo') }

    it 'returns empty array' do
      subject.articles.should be_empty
    end

    context 'when article is set to ephemeral post' do
      it 'returns assigned article', focus: true do
        # NOTE This is sample of the future syntax for associations
        association do
          from Spec::Post::Entity
          to Spec::Account::Entity
          as :account
          reverse_as :many, :articles
          #reverse_as :one, :article
        end

        through_association(
          from Spec::Post::Entity,
          to Spec::Tag::Entity, # optional ?
          as :tags
          via :essential, :taggings,
          via :incidental, :taggings,
          linked_by :tag
        )

        session.association(subject, :articles).set([post])

        session.association(subject, :articles).values.tap { |o|
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

    context 'when ephemeral post is added as article' do
      it 'returns assigned article' do
        subject.apply(articles: [:+, post]).articles.tap { |o|
          o.should eq([post])
          o.first.should be(post)
        }
      end

      it 'remembers added article after persisting' do
        pending 'not working yet'

        account_repo.persist(
          subject.apply(articles: [:+, post])
        ).articles.tap { |o|
          o.should eq([post])
          o.first.should be(post)
        }
      end

      context 'when previously added article is removed' do
        it 'returns no articles' do
          subject.apply(articles: [:+, post]).
            apply(articles: [:-, post]).articles.should be_empty
        end
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

      context 'when previously added article is removed' do
        it 'returns no articles' do
          subject.apply(articles: [:+, post]).
            apply(articles: [:-, post]).articles.should be_empty
        end
      end
    end
  end

  context 'for durable account without articles' do
    let(:subject) { account_repo.persist(account_repo.create(firstname: 'foo')) }
    let!(:post) { post_repo.create(title: 'foo') }

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

    context 'when ephemeral post is added as an article' do
      it 'returns assigned article' do
        subject.apply(articles: [:+, post]).articles.tap { |o|
          o.should eq([post])
          o.first.should be(post)
        }
      end

      it 'remembers added article after persisting' do
        pending 'not working yet'

        account_repo.persist(
          subject.apply(articles: [:+, post])
        ).articles.tap { |o|
          o.should eq([post])
          o.first.should be(post)
        }
      end

      context 'when previously added article is removed' do
        it 'returns no articles' do
          subject.apply(articles: [:+, post]).
            apply(articles: [:-, post]).articles.should be_empty
        end
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
        account_repo.persist(
          subject.apply(articles: [post])
        ).articles.tap { |o|
          o.should eq([post])
          o.first.should eq(post)
        }
      end
    end

    context 'when durable post is added as an arcicle' do
      let(:post) { post_repo.persist(super()) }

      it 'returns assigned article' do
        subject.apply(articles: [:+, post]).tap { |o|
          o.articles.should eq([post])
          o.articles.first.should be(post)
        }
      end

      it 'remembers added article after persisting' do
        account_repo.persist(
          subject.apply(articles: [:+, post])
        ).articles.tap { |o|
          o.should eq([post])
          o.first.should eq(post)
        }
      end

      context 'when previously added article is removed' do
        it 'returns no articles' do
          subject.apply(articles: [:+, post]).
            apply(articles: [:-, post]).articles.should be_empty
        end
      end
    end
  end

  context 'for durable account with articles' do
    let(:subject) { account_repo.persist(account_repo.create(firstname: 'foo')) }
    let!(:prior_post) { post_repo.persist(post_repo.create(title: 'foo', author: subject)) }
    let(:post) { post_repo.create(title: 'bar') }

    it 'returns array with prior article' do
      subject.articles.should eq([prior_post])
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

    context 'when ephemeral post is added as an article' do
      it 'returns assigned article in addition to prior article' do
        subject.apply(articles: [:+, post]).articles.tap { |o|
          o.should eq([prior_post, post])
          o.last.should be(post)
        }
      end

      it 'remembers added article after persisting' do
        pending 'not working yet'

        account_repo.persist(
          subject.apply(articles: [:+, post])
        ).articles.tap { |o|
          o.should eq([prior_post, post])
          o.last.should be(post)
        }
      end

      context 'when previously added article is removed' do
        it 'returns only prior article' do
          subject.apply(articles: [:+, post]).
            apply(articles: [:-, post]).articles.should eq([prior_post])
        end
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
        account_repo.persist(
          subject.apply(articles: [post])
        ).articles.tap { |o|
          o.should eq([post])
          o.first.should eq(post)
        }
      end
    end

    context 'when durable post is added as an article' do
      let(:post) { post_repo.persist(super()) }

      it 'returns assigned article' do
        subject.apply(articles: [:+, post]).tap { |o|
          o.articles.should eq([prior_post, post])
          o.articles.last.should be(post)
        }
      end

      it 'remembers added article after persisting' do
        account_repo.persist(
          subject.apply(articles: [:+, post])
        ).articles.tap { |o|
          o.should eq([prior_post, post])
          o.last.should eq(post)
        }
      end

      context 'when previously added article is removed' do
        it 'returns only prior article' do
          subject.apply(articles: [:+, post]).
            apply(articles: [:-, post]).articles.should eq([prior_post])
        end
      end
    end
  end
=end
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
      one_to_many :articles, Spec::Post::Entity, inverse_of: :author
    end
  end

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
