## [Unreleased]

- refactor: reorganize the overall structure of the test. Change from rspec to minitest

## [0.6.0] - 2024-11-11

- refactor: limit the scope of methods needed only for internal library purposes.
- support rails 8.0.x
- add optional value `if` to exclude from save (or destroy).

## [0.5.0] - 2024-10-09

- remove `:context` option. use `:destroy` option instead.
- remove `:destroy` option from `InnerModelCollection#destroy`.

## [0.4.1] - 2024-09-20

- Omitted optional argument for `InnerModelCollection#destroy`.
  `InnerModel` equivalence is always performed based on the instance of the inner `model`.
  Since there are no use cases that depend on the original behavior.

## [0.4.0] - 2024-09-15

- support `destrpy` option. and deprecated `context` option.
  `:context` will be removed in 0.5.0. Use `:destroy`  option instead.
  for example,
  - `models.push(model, context: :destroy)` is replaced by `models.push(model, destroy: true)`
  - `models.push(model, context: -> { foo? ? :destroy : :save })` is replaced by `models.push(model, destroy: -> { foo? })`
  - `models.push(model, context: ->(m) { m.bar? ? :destroy : :save })` is replaced by `models.push(model, destroy: ->(m) { m.bar? })`
- `destroy` option can now be specified with a `Symbol` representing the method name.

## [0.3.4] - 2024-09-01

- ci: removed sqlite3 version specifing for new AR.
- `delegate_attribute` options are now specific and do not accept `prefix`

## [0.3.3] - 2024-06-24

- use steep:ignore

## [0.3.2] - 2024-04-10

- support `ActiveRecord::Base#with_connection`
- rbs maintained.
- relax context proc arity.

## [0.3.1] - 2024-03-17

- purge nodoc definitions from type signature
- support `ActiveRecord::Base#lease_connection`

## [0.3.0] - 2024-02-24

- strictify type checking
- testing with CI even in the head version of rails
- consolidate the main process of saving into the `#save` method
- leave transaction control to ActiveRecord::Transactions
- execution of `before_commit`, `after_commit` and `after_rollback` hook is delayed until after the database commit (or rollback).

## [0.2.1] - 2024-01-31

- in `#save` (without bang), `ActiveRecord::RecordInvalid` error is not passed outward.

## [0.2.0] - 2024-01-21

- add i18n doc.
- add sig/
- add typecheck for ci.

## [0.1.8] - 2024-01-16

- avoid executing `#save!` from `Model#save`
- on save, ignore nil elements from models.

## [0.1.7] - 2024-01-15

- remove `add_development_dependency` from gemspec
- add spec for DelegateAttribute module
- add and refactor doc.

## [0.1.6] - 2024-01-14

- add doc for `#save` and `#save!`.
- implement `#save` for symmetry with `#save!`
- add `InnerModel#initialize` doc.

## [0.1.5] - 2024-01-11

- when invalid, raises ActiveRecord::RecordInvalid on #save!

## [0.1.4] - 2024-01-10

- remove uniquely defined exception class.

## [0.1.3] - 2024-01-09

- fix documentation uri.

## [0.1.2] - 2024-01-09

- fix and add doc.
- add development dependency
- avoid instance variable name conflict (`@models` to `@__models`)
- add #empty?, #clear to InnerModelCollection
- add #delete to InnerModelCollection

## [0.1.1] - 2024-01-08

- fix 0.1.0 release date.
- add doc.
- Make it easier for application developers to work with `#models`

## [0.1.0] - 2024-01-06

- Initial release
