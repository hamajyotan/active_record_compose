## [Unreleased]

- remove `add_development_dependency` from gemspec
- add spec for DelegateAttribute module

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
