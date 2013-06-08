# ORMivore

## Synopsis

ORM framework for **long lived** ruby projects with a twist.

## Stability

ORMivore is in the R&D 'alpha' stage. In other words, it is my
playground for experimenting with new approach to ORM. Changes are
definitely not backward compatible. If you decide to use it, prepare to
roll up your sleeves, and I disclaim any petential indirect harm to kittens.
If I still need to spell it out to you - ORMivore is not production
ready yet.

## Motivation

If you have seen legacy Rails app, chances are you have noticed:

- persistance logic hopelessly coupled with business logic
- business rules are forming one clump
- copious amounts of logged SQL that is hard to relate back to application code
- bad performance and high database load caused by inefficient SQL
queries

ORMivore helps you to either avoid those issues on your project, or to
slowly eliminate them on your legacy app.

## Philosophy summary

- Everything the system does FOR you, the system also does TO you
- Actions that will lead to long term pain better be painfull
immediately, and never sugar-coated with short term gain
- There is much to be learned from functional programming

## Philosophy explained

Many ORMs simply do too good of a job - they isolate developers from
storage so much that they choose to pretend it is just an inconvenient
abstraction, and ignore it as much as possible. That causes huge loss of
database efficiency. ORMivore does not abstract storage too far away -
it does only the bare minimum. No automatic associations management, no
callbacks, no frills at all.

OOD is great, but frequently overused. ORMivore uses plain data
structures to communicate between different layers, solving problem of
messy circular dependencies.

Mutable entities have state, and that makes reasoning about them more
difficult. Immutable entities discourage placing any "how-to"
behavior on them, making them a good place for "what is" messages.
As a side benefit, immutable entities play well in multi-treaded
environments.

Ports and adapters pattern (hexagonal architecture) is great for
isolating persistance logic from entities. It also allowes for some
degree of substitutability of different storages.

## Installation

Well, I have not built gem for this project yet, but when I do, just add 'gem
"ormivore"' to Gemfile, or run 'gem install ormivore'.

## Code Example

```ruby
new_account = Account.new(firstname: 'John', lastname: 'Doe')

saved_account = repo.persist(account)

changed_account = saved_account.prototype(firstname: 'Jane')

saved_changed_account = repo.persist(changed_account)

reloaded_account = repo.find_by_id(saved_changed_account.id)
```

## Tests

To run tests on ORMivore and empedded sample add, follow this script:

```bash
gem install bundle

bundle install --path vendor/bundle

bundle exec rake spec
```

## Contributors

At this point, this is the playground of experimentation, and it does
not have to be only mine! Forks and pull requests are welcome.

## License

One word - MIT
