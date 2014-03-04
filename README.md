# ORMivore

[![Build Status](https://secure.travis-ci.org/olek/ormivore.png)](http://travis-ci.org/olek/ormivore)

## Synopsis

Persistence isolation framework for long term ruby projects.

Or, "Half, not Half-Assed" approach to ORM.

## Caution

ORMivore is highly opinionated and does not quite follow conventional
rules of wisdom in ruby/rails community.

## Audience

People that value ability to maintain app after it is couple years old,
or want to get legacy app back under control.

On the other hand, if quick throw-away projects that require no
extension/maintenance in the future are the story of your life,
probably ORMivore is not for you.

## Stability

ORMivore is in the R&D 'alpha' stage. In other words, it is playground
for experimentation. Changes are highly likely to be not backward
compatible. If you decide to use it, prepare to roll up your sleeves,
and I disclaim any potential indirect harm to kittens.

Just to state the obvious - ORMivore is not production ready just yet.

## Motivation

If you have seen legacy Rails app, chances are you noticed:

- persistance logic tightly coupled with business logic
- business rules forming one clump
- copious amounts of logged SQL that is hard to relate back to application code
- bad performance and high database load caused by runaway (and inefficient) SQL
queries

ORMivore is designed to help in either avoiding those issues on new
project, or slowly eliminating them on a legacy app.

## Philosophy summary

- Everything the system does FOR you, the system also does TO you
- Actions that will lead to long term pain better be painful
immediately, and never sugar-coated with short term gain
- Long term maintenability trumps supersonic speed of initial development
- There is much to be learned from functional programming
- So much complexity in software comes from trying to make one thing do
  two things (Ryan Singer)

## Philosophy explained

OOD is great, but have to be applied with care. ORMivore uses plain data
structures (functional style) to communicate between different layers,
solving problem of messy circular dependencies.

Mutable entities have state, and that makes reasoning about them more
difficult. Immutable entities are easy to reason about and discourage
placing any "how to" behavior on them, making them a good place for
"what is" messages.  As a side benefit, immutable entities play well in
multi-threaded environments.

Many ORM make it too easy to conflate business logic and persistence.
Ports and adapters pattern (hexagonal architecture) are core of
ORMivore, and it is great for isolating persistance logic from entities.
It also allows for some degree of substitutability of different storages.

Putting responsibility of managing data and managing association in one
same object leads to many lies inside of code that quickly relult in a
lot of complexity. It is much simpler to divide those responsibilities
(not easier, but much simpler).

While STI and polymorphic relations are bad for your health, your legacy
database is probably littered with them, and ORMivore provides means to
map those to domain objects in a 'class-less' way.
That makes it possible to introduce ORMivore entities in the same
project/process as legacy ActiveRecord models.

## Installation

Just add 'gem "ormivore"' to Gemfile, or run 'gem install ormivore'.

## Basic Code Example

Typical setup would include a bit of boiler plate code that would look a
little ridiculous for such simple example heere. This example is using
shortcuts that generate boiler plate classes automatically, but for real
production code spelling things out probably is better, it will come
handy when real functionality and tests are added.

This is complete example that can be copy/pasted in the console, and
will work. It uses memory adapter to avoid having to configure database
access, but code change to get it to work with SQL database is trivial.

```ruby

Sample = Module.new

ORMivore::create_entity_skeleton(Sample, :post, port: true, repo: true, memory_adapter: true) do
  attributes do
    string :title
    string :body
  end
end

ORMivore::create_entity_skeleton(Sample, :tag, port: true, repo: true, memory_adapter: true) do
  attributes do
    string :name
  end
end

ORMivore::create_entity_skeleton(Sample, :tagging, port: true, repo: true, memory_adapter: true) do
  attributes do
    integer :post_id
    integer :tag_id
  end
end

module Sample
  class Associations
    extend ORMivore::Association::AssociationDefinitions

    association do
      from Tagging::Entity
      to Post::Entity
      as :post
      reverse_as :many, :taggings
    end

    association do
      from Tagging::Entity
      to Tag::Entity
      as :tag
    end

    transitive_association do
      from Post::Entity
      to Tag::Entity
      as :tags
      via :incidental, :taggings
      linked_by :tag
    end
  end

  module Repos
    extend ORMivore::RepoFamily
  end

  Post::Repo.new(Post::Entity, Post::StoragePort.new(Post::StorageMemoryAdapter.new), family: Repos)
  Tag::Repo.new(Tag::Entity, Tag::StoragePort.new(Tag::StorageMemoryAdapter.new), family: Repos)
  Tagging::Repo.new(Tagging::Entity, Tagging::StoragePort.new(Tagging::StorageMemoryAdapter.new), family: Repos)
  Repos.freeze
end

session = ORMivore::Session.new(Sample::Repos, Sample::Associations) # #<ORMivore::Session:0x7ffe1beef7c0>
post = session.repo.post.create(title: 'foo', body: 'bar') # #<Sample::Post::Entity derived attributes={:title=>"foo", :body=>"bar"}>
post = post.apply(body: 'baz') # #<Sample::Post::Entity derived attributes={:title=>"foo", :body=>"baz"}>
session.association(post, :tags).values # []
t1 = session.repo.tag.create(name: 't1') # #<Sample::Tag::Entity derived attributes={:name=>"t1"}>
session.association(post, :tags).add(t1) # [#<Sample::Tagging::Entity derived attributes={:post_id=>-1, :tag_id=>-1}>]
session.association(post, :tags).values # [#<Sample::Tag::Entity derived attributes={:name=>"t1"}>]
session.association(post, :taggings).values # [#<Sample::Tagging::Entity derived attributes={:post_id=>-1, :tag_id=>-1}>]
session.commit # [Sample::Post::Entity, Sample::Tag::Entity, Sample::Tagging::Entity]

session = ORMivore::Session.new(Sample::Repos, Sample::Associations) # #<ORMivore::Session:0x7ffe1be699e0>
post = session.repo.post.find_by_id(1) # #<Sample::Post::Entity root id=1 attributes={:title=>"foo", :body=>"baz"}>
session.association(post, :tags).values # [#<Sample::Tag::Entity root id=1 attributes={:name=>"t1"}>]
session.association(post, :taggings).values # [#<Sample::Tagging::Entity root id=1 attributes={:post_id=>1, :tag_id=>1}>]


```

## In Depth Code Examples

Check integration specs for more in depth examples. Also...
Monologue blog app is in the process of being ported to ORMivore, check
it out (it is work in progress).

## Tests

To run tests on ORMivore and embedded sample app, run something along
those lines:

```bash
gem install bundle

bundle install --path vendor/bundle

bundle exec rake spec
```

## Contributors

At this point, this is the playground of experimentation, and it does
not have to be just mine! Forks and pull requests are welcome. Of
course, I reserve the right to politely decline or ruthlessly
'refactor'.

## License

MIT

## Apologies

> Documentation is like sex: when it is good, it is very, very good; and when it is bad, it is better than nothing.

This README is certainly not enough, but it is indeed better than nothing.

English is not my 'mother tongue'. I am sure this document is littered
with mistaekes. If your english is any better than mine - please help me
fix them.
