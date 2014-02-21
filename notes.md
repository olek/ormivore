# Notes

## Vision

- Entities should be strictly read-only, and versioned. As a result,
they are thread-safe (really a side effect). They are also easy to
reason about, because same 'question' will always yield same 'answer'
- It is OK for code to use 'past' (old) versions of entity, as long as it
does not try to modify or persist it (in that case - fail quick).
- Entities can be created/loaded/persisted by storage repos in ad-hoc
way. But this is not the main use case of the ORMivore, and is more of
the corner case. One of the large limitations - only direct foreign key
associations are available in this mode.
- There should be a session that will contain association collections
and reverse associations, repo finder cache, identity map, and unit of
work.
- Direct foreign key associations should be on entity itself and should
be subject of revision with it. In other words, they live in their host
entity timeline.
- Association collections should be maintained by session, not entity.
They are NOT in entity timeline and are NOT revised with it. They are in
the 'inverse' entity timeline, where they are just direct foreign key
associations.
- Intersection/combination/interaction of timelines of different entities forms
session timeline.
- Session is created by providing a repo family to it.
- Session should assign temporary identity to ephemeral entities. Maybe.
Or maybe it is better to use double-linked list for entity timeline,
eliminating need for temporary identity. TBD.
- Session should use repo proxies that memoize results of the finder
calls and make sure to refresh (call .current) memoized entities each
time they are returned. Using proxy pattern here should be safe since
proxy will never have to return itself :)
- Session should use identity map in order to avoid having more than one
instance of object with same identity loaded.
- Session should provide means to get association collections
(one_to_many, many_to_many) and reverse associations by running
(cacheable) db query, and then also iterating over all
ephemeral/revised/deleted entities of specified class and manipulating
result set.
- As optimization, concept of 'foreign key version' may be introduced,
where whenever a foreign key of a given entity class is changed, its
session-wide version increments. This will allow for caching association
collections for some time.
- Session repo proxies should fail if they are asked to persist entity.
- Session itself should have end of life: commit (persist), rollback
(discard all changed), drop (for read-only sessions, will cause error if
any changes were made to entities inside it).
- Session persistance algorithm:
  - collect all ephemeral entities
    - for those of them that have no associations to other ephemeral
entities, persist, and repeat same step.
    - if prior step is impossible, select ephemeral entity with the smallest
number of of nullable fk associations to ephemeral entities, delete
those associations, persist it, then re-add previously deleted
associations (will cause an update a little later), then go to prior step

## Ideas

- lazy coercion of attributes, at least dates
- identity map should be dirt cheap and dead easy to implement with
- add support for transactions (long in the future)
immutable entities.

## Think about it.

- figure out how to allow for 'callbacks' implementation by creating wrapper repo
- figure out how/when to do validation
