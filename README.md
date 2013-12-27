# ORMivore

[![Build Status](https://secure.travis-ci.org/olek/ormivore.png)](http://travis-ci.org/olek/ormivore)

## Synopsis

Persistence isolation framework for long term ruby projects.
Not really an ORM, but a way to tame one.

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

Just to state the obvious - ORMivore is not production ready just yet, and maybe will never be.

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

## Philosophy explained

Many ORMs simply do too good of a job - they isolate developers from
storage so much that developers choose to pretend it is just an inconvenient
abstraction, and ignore it as much as possible. That causes huge loss of
database efficiency. ORMivore does not abstract storage too far away -
it does only the bare minimum. No automatic associations management, no
callbacks, no frills at all.

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

While STI and polymorphic relations are bad for your health, your legacy
database is probably littered with them, and ORMivore provides means to
map those to domain objects in a 'class-less' way.
That makes it possible to introduce ORMivore entities in the same
project/process as legacy ActiveRecord models.

## Installation

Just add 'gem "ormivore"' to Gemfile, or run 'gem install ormivore'.

## Basic Code Example

There is quite a bit of boiler plate code here that looks a little
ridiculous for such a simple example, but it will come handy when
real functionality and tests are added.

```ruby
class Account
  include ORMivore::Entity

  attributes(
    firstname: String,
    lastname: String,
    email: String
  )
end

class NoopConverter
  def attributes_list_to_storage(list)
    list
  end

  def from_storage(attrs)
    attrs
  end

  def to_storage(attrs)
    attrs
  end
end

class AccountStorageMemoryAdapter
  include ORMivore::MemoryAdapter

  self.default_converter_class = NoopConverter
end

class AccountStorageArAdapter
  include ORMivore::ArAdapter

  self.table_name = 'accounts'
  self.default_converter_class = NoopConverter
end

class AccountStoragePort
  include ORMivore::Port
end

class AccountRepo
  include ORMivore::Repo

  self.default_entity_class = App::Account
end

mem_db_repo = AccountRepo.new(AccountStoragePort.new(AccountStorageMemoryAdapter.new), Account)
sql_db_repo = AccountRepo.new(AccountStoragePort.new(AccountStorageArAdapter.new), Account)
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: 'db/db.sqlite3')

new_account = Account.new(firstname: 'John', lastname: 'Doe')

saved_to_mem_db_account = mem_db_repo.persist(new_account)

changed_account = saved_to_mem_db_account.apply(firstname: 'Jane')

saved_to_mem_db_changed_account = mem_db_repo.persist(changed_account)

reloaded_from_mem_db_account = mem_db_repo.find_by_id(saved_to_mem_db_account.id)

saved_to_sql_db_account = sql_db_repo.persist(new_account)
```

## In Depth Code Examples

Just look under app/ directory for the setup of sample project that is
used by test cases.

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
