# ActiveRecordCompose

ActiveRecordCompose lets you build form objects that combine multiple ActiveRecord models into a single, unified interface.
More than just a simple form object, it is designed as a **business-oriented composed model** that encapsulates complex operations-such as user registration spanning multiple tables-making them easier to write, validate, and maintain.

[![Gem Version](https://badge.fury.io/rb/active_record_compose.svg)](https://badge.fury.io/rb/active_record_compose)
![CI](https://github.com/hamajyotan/active_record_compose/workflows/CI/badge.svg)
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/hamajyotan/active_record_compose)

## Table of Contents

- [Motivation](#motivation)
- [Installation](#installation)
- [Quick Start](#quick-start)
  - [Basic Example](#basic-example)
  - [Attribute Delegation](#attribute-delegation)
  - [Unified Error Handling](#unified-error-handling)
  - [I18n Support](#i18n-support)
- [Advanced Usage](#advanced-usage)
  - [Destroy Option](#destroy-option)
  - [Callback ordering with `#persisted?`](#callback-ordering-with-persisted)
  - [Notes on adding models dynamically](#notes-on-adding-models-dynamically)
- [Sample Application](#sample-application)
- [Links](#links)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)
- [Code of Conduct](#code-of-conduct)

## Motivation

In Rails, `ActiveRecord::Base` is responsible for persisting data to the database.
By defining validations and callbacks, you can model use cases effectively.

However, when a single model must serve multiple different use cases, you often end up with conditional validations (`on: :context`) or workarounds like `save(validate: false)`.
This mixes unrelated concerns into one model, leading to unnecessary complexity.

`ActiveModel::Model` helps here — it provides the familiar API (`attribute`, `errors`, validations, callbacks) without persistence, so you can isolate logic per use case.

**ActiveRecordCompose** builds on `ActiveModel::Model` and is a powerful **business object** that acts as a first-class model within Rails.
- Transparently accesses attributes across multiple models
- Saves all associated models atomically in a transaction
- Collects and exposes error information consistently

This leads to cleaner domain models, better separation of concerns, and fewer surprises in validations and callbacks.

## Installation

To install `active_record_compose`, just put this line in your Gemfile:

```ruby
gem 'active_record_compose'
```

Then bundle

```sh
$ bundle
```

## Quick Start

### Basic Example

Suppose you have two models:

```ruby
class Account < ApplicationRecord
  has_one :profile
  validates :name, :email, presence: true
end

class Profile < ApplicationRecord
  belongs_to :account
  validates :firstname, :lastname, :age, presence: true
end
```

You can compose them into one form object:

```ruby
class UserRegistration < ActiveRecordCompose::Model
  def initialize(attributes = {})
    @account = Account.new
    @profile = @account.build_profile
    super(attributes)
    models << account << profile
  end

  attribute :terms_of_service, :boolean
  validates :terms_of_service, presence: true
  validates :email, confirmation: true

  after_commit :send_email_message

  delegate_attribute :name, :email, to: :account
  delegate_attribute :firstname, :lastname, :age, to: :profile

  private

  attr_reader :account, :profile

  def send_email_message
    SendEmailConfirmationJob.perform_later(account)
  end
end
```

Usage:

```ruby
# === Standalone script ===
registration = UserRegistration.new
registration.update!(
  name: "foo",
  email: "bar@example.com",
  firstname: "taro",
  lastname: "yamada",
  age: 18,
  email_confirmation: "bar@example.com",
  terms_of_service: true,
)
# `#update!` SQL log
#   BEGIN immediate TRANSACTION
#   INSERT INTO "accounts" ("created_at", "email", "name", "updated_at") VALUES (...
#   INSERT INTO "profiles" ("account_id", "age", "created_at", "firstname", "lastname", ...
#   COMMIT TRANSACTION


# === Or, in a Rails controller with strong parameters ===
class UserRegistrationsController < ApplicationController
  def create
    @registration = UserRegistration.new(user_registration_params)
    if @registration.save
      redirect_to root_path, notice: "Registered!"
    else
      render :new
    end
  end

  private
  def user_registration_params
    params.require(:user_registration).permit(
      :name, :email, :firstname, :lastname, :age, :email_confirmation, :terms_of_service
    )
  end
end
```

Both `Account` and `Profile` will be updated **atomically in one transaction**.

### Attribute Delegation

`delegate_attribute` allows transparent access to attributes of inner models:

```ruby
delegate_attribute :name, :email, to: :account
delegate_attribute :firstname, :lastname, :age, to: :profile
```

They are also included in `#attributes`:

```ruby
registration.attributes
# => {
#   "terms_of_service" => true,
#   "email" => nil,
#   "name" => "foo",
#   "age" => nil,
#   "firstname" => nil,
#   "lastname" => nil
# }
```

### Unified Error Handling

Validation errors from inner models are collected into the composed model:

```ruby
user_registration = UserRegistration.new(
  email: "foo@example.com",
  email_confirmation: "BAZ@example.com",
  age: 18,
  terms_of_service: true,
)

user_registration.save # => false

user_registration.errors.full_messages
# => [
#   "Name can't be blank",
#   "Firstname can't be blank",
#   "Lastname can't be blank",
#   "Email confirmation doesn't match Email"
# ]
```

### I18n Support

When `#save!` raises `ActiveRecord::RecordInvalid`,
make sure you have locale entries such as:

```yaml
en:
  activemodel:
    errors:
      messages:
        record_invalid: 'Validation failed: %{errors}'
```

For more complete usage patterns, see the [Sample Application](#sample-application) below.

## Advanced Usage

### Destroy Option

```ruby
models.push(profile, destroy: true)
```

This deletes the model on `#save` instead of persisting it.
Conditional deletion is also supported:

```ruby
models.push(profile, destroy: -> { profile_field_is_blank? })
```

### Callback ordering with `#persisted?`

The result of `#persisted?` determines **which callbacks are fired**:

- `persisted? == false` -> create callbacks (`before_create`, `after_create`, ...)
- `persisted? == true` -> update callbacks (`before_update`, `after_update`, ...)

This matches the behavior of normal ActiveRecord models.

```ruby
class ComposedModel < ActiveRecordCompose::Model
  before_save     { puts "before_save" }
  before_create   { puts "before_create" }
  before_update   { puts "before_update" }
  after_create    { puts "after_create" }
  after_update    { puts "after_update" }
  after_save      { puts "after_save" }

  def persisted?
    account.persisted?
  end
end
```

Example:

```ruby
# When persisted? == false
model = ComposedModel.new

model.save
# => before_save
# => before_create
# => after_create
# => after_save

# When persisted? == true
model = ComposedModel.new
def model.persisted?; true; end

model.save
# => before_save
# => before_update
# => after_update
# => after_save
```

### Notes on adding models dynamically

Avoid adding `models` to the models array **after validation has already run**
(for example, inside `after_validation` or `before_save` callbacks).

```ruby
class Example < ActiveRecordCompose::Model
  before_save { models << AnotherModel.new }
end
```

In this case, the newly added model will **not** run validations for the current save cycle.
This may look like a bug, but it is the expected behavior: validations are only applied
to models that were registered before validation started.

We intentionally do not restrict this at the framework level, since there may be valid
advanced use cases where models are manipulated dynamically.
Instead, this behavior is documented here so that developers can make an informed decision.

## Sample Application

The sample app demonstrates a more complete usage of ActiveRecordCompose
(e.g., user registration flows involving multiple models).
It is not meant to cover every possible pattern, but can serve as a reference
for putting the library into practice.

Try it out in your browser with GitHub Codespaces (or locally):

- https://github.com/hamajyotan/active_record_compose-example

## Links

- [API Documentation (YARD)](https://hamajyotan.github.io/active_record_compose/)
- [Blog article introducing the concept](https://dev.to/hamajyotan/smart-way-to-update-multiple-models-simultaneously-in-rails-51b6)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/hamajyotan/active_record_compose. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/hamajyotan/active_record_compose/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ActiveRecord::Compose project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/hamajyotan/active_record_compose/blob/main/CODE_OF_CONDUCT.md).

