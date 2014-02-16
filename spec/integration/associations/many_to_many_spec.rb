require 'spec_helper'

shared_examples_for 'a many-to-many association' do
  let(:family) { ORMivore::AnonymousFactory::create_repo_family.new }

  let(:post_port) { Spec::Post::StoragePort.new(post_adapter) }
  let!(:post_repo) { Spec::Post::Repo.new(Spec::Post::Entity, post_port, family: family) }

  let(:tag_port) { Spec::EarTag::StoragePort.new(tag_adapter) }
  let!(:tag_repo) { Spec::EarTag::Repo.new(Spec::EarTag::Entity, tag_port, family: family) }

  let(:tagging_port) { Spec::EarTagging::StoragePort.new(tagging_adapter) }
  let!(:tagging_repo) { Spec::EarTagging::Repo.new(Spec::EarTagging::Entity, tagging_port, family: family) }

  let(:subject) { post_repo.create(title: 'foo') }
  let(:tag) { tag_repo.create(name: 'foo') }

  context 'for ephemeral post' do
    it 'returns empty array' do
      subject.taggings.should be_empty
      subject.tags.should be_empty
    end

    context 'when tag is set to ephemeral tag' do
      let(:subject) { super().apply(tags: [tag]) }

      it 'returns assigned tag' do
        subject.tags.tap { |o|
          o.should eq([tag])
          o.first.should be(tag)
        }
      end

      it 'creates new tagging for assigned tag' do
        subject.taggings.tap { |o|
          o.should have(1).taggings
          o.first.article.should be(subject.send(:parent))
          o.first.tag.should be(tag)
        }
      end

      context 'after persisting' do
        let(:subject) { post_repo.persist(super()) }

        it 'remembers assigned tag' do
          pending 'not working yet'

          subject.tags.tap { |o|
            o.should eq([tag])
            o.first.should be(tag)
          }
        end
      end
    end
  end

  context 'for durable post' do
    let(:subject) { post_repo.persist(super()) }

    it 'returns empty array' do
      subject.taggings.should be_empty
      subject.tags.should be_empty
    end

    context 'when tag is set to durable tag' do
      let(:subject) { super().apply(tags: [tag]) }
      let(:tag) { tag_repo.persist(super()) }

      it 'returns assigned tag' do
        subject.tags.tap { |o|
          o.should eq([tag])
          o.first.should be(tag)
        }
      end

      context 'after persisting' do
        let(:subject) { post_repo.persist(super()) }

        it 'remembers assigned tag' do
          subject.tags.tap { |o|
            o.should eq([tag])
            o.first.should eq(tag)
          }
        end
      end
    end

    context 'when ephemeral tagging pointing to durable tag is added' do
      let(:subject) { super().apply(taggings: [:+, tagging]) }
      let(:tag) { tag_repo.persist(super()) }
      let(:tagging) { tagging_repo.create(tag: tag) }

      it 'returns assigned tag' do
        subject.tags.tap { |o|
          o.should eq([tag])
          o.first.should be(tag)
        }
      end

      context 'after persisting' do
        let(:subject) { post_repo.persist(super()) }

        it 'remembers assigned tag' do
          subject.tags.tap { |o|
            o.should eq([tag])
            o.first.should eq(tag)
          }
        end
      end
    end
  end
end

describe 'an association between post and its author' do
  before do
    Object.send(:remove_const, :Spec) if Object.const_defined?(:Spec)
    Spec = Module.new

    ORMivore::create_entity_skeleton(Spec, :ear_tag, port: true, repo: true) do
      attributes do
        string :name
      end
    end

    ORMivore::create_entity_skeleton(Spec, :ear_tagging, port: true, repo: true) do
      one_to_one :tag, Spec::EarTag::Entity, fk: :tag_id
    end

    ORMivore::create_entity_skeleton(Spec, :post, port: true, repo: true) do
      attributes do
        string  :title
      end
      one_to_many :taggings, Spec::EarTagging::Entity, inverse_of: :article
      many_to_many :tags, Spec::EarTag::Entity, through: :taggings, source: :tag
    end

    Spec::EarTagging::Entity.instance_eval do
      one_to_one :article, Spec::Post::Entity, fk: :post_id, inverse_of: :taggings
    end
  end

  after do
    Object.send(:remove_const, :Spec) if Object.const_defined?(:Spec)
  end

  context 'with StorageMemoryAdapter', :memory_adapter do
    let(:post_adapter) { ORMivore::AnonymousFactory::create_memory_adapter.new }
    let(:tag_adapter) { ORMivore::AnonymousFactory::create_memory_adapter.new }
    let(:tagging_adapter) { ORMivore::AnonymousFactory::create_memory_adapter.new }

    it_behaves_like 'a many-to-many association'
  end

  context 'with StorageArAdapter', :secondary_adapter, :ar_db do
    let(:post_adapter) { ORMivore::AnonymousFactory::create_ar_adapter('posts').new }
    let(:tag_adapter) { ORMivore::AnonymousFactory::create_ar_adapter('tags').new }
    let(:tagging_adapter) { ORMivore::AnonymousFactory::create_ar_adapter('taggings').new }

    it_behaves_like 'a many-to-many association'
  end

  context 'with StorageSequelAdapter', :secondary_adapter, :sequel_db do
    let(:post_adapter) { ORMivore::AnonymousFactory::create_sequel_adapter('posts').new }
    let(:tag_adapter) { ORMivore::AnonymousFactory::create_sequel_adapter('tags').new }
    let(:tagging_adapter) { ORMivore::AnonymousFactory::create_sequel_adapter('taggings').new }

    it_behaves_like 'a many-to-many association'
  end

  context 'with StoragePreparedSequelAdapter', :sql_adapter, :sequel_db do
    let(:post_adapter) { ORMivore::AnonymousFactory::create_prepared_sequel_adapter('posts').new }
    let(:tag_adapter) { ORMivore::AnonymousFactory::create_prepared_sequel_adapter('tags').new }
    let(:tagging_adapter) { ORMivore::AnonymousFactory::create_prepared_sequel_adapter('taggings').new }

    it_behaves_like 'a many-to-many association'
  end

=begin should we test associations with redis? it lacks generic find interface...
  context 'with StorageRedisAdapter', :redis_db do
  end
=end
end
