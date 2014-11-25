require 'spec_helper'

shared_examples_for 'a many-to-many association' do
  let(:family) { ORMivore::AnonymousFactory::create_repo_family.new }

  let(:post_port) { Spec::Post::StoragePort.new(post_adapter) }
  let(:tag_port) { Spec::EarTag::StoragePort.new(tag_adapter) }
  let(:tagging_port) { Spec::EarTagging::StoragePort.new(tagging_adapter) }

  let(:post_repo) { session.repo.post }
  let(:tagging_repo) { session.repo.tagging }
  let(:tag_repo) { session.repo.tag }

  let(:session) { ORMivore::Session.new(family, associations) }

  let(:subject) { post_repo.create(title: 'foo') }
  let(:tag) { tag_repo.create(name: 'foo') }

  let(:association) {
    session.association(subject, :tags)
  }

  let(:via_association) {
    session.association(subject, :taggings)
  }

  before do
    Spec::Post::Repo.new(Spec::Post::Entity, post_port, family: family)
    Spec::EarTagging::Repo.new(Spec::EarTagging::Entity, tagging_port, family: family)
    Spec::EarTag::Repo.new(Spec::EarTag::Entity, tag_port, family: family)
  end

  context 'for ephemeral post' do
    it 'returns empty array' do
      association.values.should be_empty
      via_association.values.should be_empty
    end

    context 'when tags is set to ephemeral tag' do
      before do
        association.set(tag)
      end

      it 'returns assigned tag' do
        association.values.tap { |o|
          o.should eq([tag])
          o.first.should be(tag)
        }
      end

      it 'creates new tagging for assigned tag' do
        via_association.values.tap { |o|
          o.should have(1).taggings
          o.first.attribute(:post_id).should eq(subject.identity)
          o.first.attribute(:tag_id).should eq(tag.identity)
        }
      end

      # TODO create another set of tests for :essential via entity
      context 'when tags is un-assigned' do
        before do
          association.clear
        end

        it 'removes tag from values' do
          association.values.should be_empty
        end

        it 'removes tagging' do
          via_association.values.should be_empty
        end
      end

      context 'when post is deleted' do
        it 'deletes taggings as well' do
          tagging = via_association.values.first
          tagging_entity = tagging.dereference
          expect {
            session.delete(subject)
          }.to change { session.lookup(Spec::EarTagging::Entity, tagging_entity.identity) }.from(tagging_entity).to(nil)
        end
      end

      context 'after persisting' do
        let(:subject) { post_repo.persist(super()) }

        it 'remembers assigned tag' do
          association.values.tap { |o|
            o.should eq([tag])
            o.first.should be(tag)
          }
        end
      end
    end
  end
end

describe 'an association between post and tags' do
  before do
    Object.send(:remove_const, :Spec) if Object.const_defined?(:Spec)
    Spec = Module.new

    ORMivore::create_entity_skeleton(Spec, :ear_tag, port: true, repo: true) do
      shorthand :tag

      attributes do
        string :name
      end
    end

    ORMivore::create_entity_skeleton(Spec, :ear_tagging, port: true, repo: true) do
      shorthand :tagging

      attributes do
        integer :post_id
        integer :tag_id
      end
    end

    ORMivore::create_entity_skeleton(Spec, :post, port: true, repo: true) do
      attributes do
        string  :title
      end
    end
  end

  let(:associations) {
    Class.new do
      extend ORMivore::Association::AssociationDefinitions

      association do
        from Spec::EarTagging::Entity
        to Spec::EarTag::Entity
        as :tag
      end

      association do
        from Spec::EarTagging::Entity
        to Spec::Post::Entity
        as :post
        reverse_as :many, :taggings
      end

      transitive_association do
        from Spec::Post::Entity
        to Spec::EarTag::Entity
        as :tags
        via :incidental, :taggings
        linked_by :tag
      end
    end
  }

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
