# Notes

## TODOs

- add Redis adapter
- add a functionality to repo that allows querying for multiple entities
by thier ids, returning map of id to found entity; even better - allow
arbitrary input objects, require block that translates that input object
to id, and return map of objects to found entities
- add support for transactions
- add optional 'finder' cache
- add optional identity map
- add simple SQL / Sequel adapter instead / in addition to AR
- ArAdapter is really ugly; replace it with some simple Sql adapter without AR 'goodness'

## Ideas

- figure out how to allow for 'callbacks' implementation by creating wrapper repo
- figure out how/when to do validation
- add simple application using the ORMivore in addition to sample
entities
- identity map should be dirt cheap and dead easy to implement with
immutable entities. Add it to a repo, maybe use decorator pattern?
- getting identity map / finder cache to work with custom finders might
be tricky.
