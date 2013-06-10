# ORMivore

## Synopsis

ORM framework for **long lived** ruby projects with a twist.

## Caution

ORMivore is highly opinionated and does not quite follow conventional
rules of wisdom in ruby/rails community. If you want to follow
mainstream 'rails way' - stay away.

## Audience

If you want to be able to maintain your app in couple years, or want
to get legacy app back under control, ORMivore may have something
for you.

On the other hand, if quick throw-away projects that require no extension/maintenance in
the future are your goal, ORMivore is a waste of time and effort for you.

## Stability

ORMivore is in the R&D 'alpha' stage. In other words, it is my
playground for experimenting with new approach to ORM. Changes are
definitely not backward compatible. If you decide to use it, prepare to
roll up your sleeves, and I disclaim any potential indirect harm to kittens.

In other words - ORMivore is not production ready just yet.

## Motivation

If you have seen legacy Rails app, chances are you noticed:

- persistance logic tightly coupled with business logic
- business rules are forming one clump
- copious amounts of logged SQL that is hard to relate back to application code
- bad performance and high database load caused by runaway (and inefficient) SQL
queries

ORMivore is designed to helps you either avoid those issues on your project, or to
slowly eliminate them on your legacy app.

## Philosophy summary

- Everything the system does FOR you, the system also does TO you
- Actions that will lead to long term pain better be painfull
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
multi-treaded environments.

Ports and adapters pattern (hexagonal architecture) is great for
isolating persistance logic from entities. It also allows for some
degree of substitutability of different storages.

While STI and polymorphic relations are bad for your health, your legacy
database is probably littered with them, and ORMivore provides means to
map those to domain objects in a 'class-less' way.
That makes it possible to introduce ORMivore entities in the same
project/process as legacy ActiveRecord models.

## Installation

Just add 'gem "ormivore"' to Gemfile, or run 'gem install ormivore'.

## Code Example

```ruby
new_account = Account.new(firstname: 'John', lastname: 'Doe')

saved_account = repo.persist(account)

changed_account = saved_account.apply(firstname: 'Jane')

saved_changed_account = repo.persist(changed_account)

reloaded_account = repo.find_by_id(saved_changed_account.id)
```

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
