# ActiveRecordCompose

activemodel (activerecord) form object pattern. it embraces multiple AR models and provides a transparent interface as if they were a single model.

[![Gem Version](https://badge.fury.io/rb/active_record_compose.svg)](https://badge.fury.io/rb/active_record_compose)
![CI](https://github.com/hamajyotan/active_record_compose/workflows/CI/badge.svg)
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/hamajyotan/active_record_compose)

## Table of Contents

- [Motivation](#motivation)
- [Installation](#installation)
- [Usage](#usage)
  - [Basic usage](#basic-usage)
    - [`delegate_attribute`](#delegate_attribute)
    - [Promotion to model from AR-model errors](#promotion-to-model-from-ar-model-errors)
  - [I18n](#i18n)
- [Advanced Usage](#advanced-usage)
  - [`destroy` option](#destroy-option)
  - [Callback ordering by `#persisted?`](#callback-ordering-by-persisted)
  - [`#save` with custom context option](#save-with-custom-context-option)
- [Sample application as an example](#sample-application-as-an-example)
- [Links](#links)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)
- [Code of Conduct](#code-of-conduct)

## Motivation

`ActiveRecord::Base` is responsible for persisting data to the database, and by defining validations and callbacks, it allows you to structure your use cases effectively. This is a crucial component of Rails. However, when a specific model starts being updated by multiple different use cases, validations and callbacks may require conditions such as `on: :context` or `save(validate: false)`. As a result, the model needs to account for multiple dependent use cases, leading to increased complexity.

In such cases, `ActiveModel::Model` becomes useful. It provides the same interfaces as `ActiveRecord::Base`, such as `attribute` and `errors`, allowing it to be used similarly to an ActiveRecord model. Additionally, it enables you to define validations and callbacks within a limited context, preventing conditions related to multiple contexts from being embedded in `ActiveRecord::Base` validations and callbacks. This results in simpler, more maintainable code.

This gem is built on `ActiveModel::Model` and acts as a first-class model within the Rails context. It provides methods for performing batch and safe updates on 0..N encapsulated models, enables transparent attribute access, and facilitates access to error information.

## Installation

To install `active_record_compose`, just put this line in your Gemfile:

```ruby
gem 'active_record_compose'
```

Then bundle

```sh
$ bundle
```

## Usage

### Basic usage

(Below, it is assumed that there are two AR model definitions, `Account` and `Profile`, for the sake of explanation.)

```ruby
class Account < ApplicationRecord
  has_one :profile  # can work without `autosave:true`
  validates :name, :email, presence: true
end

class Profile < ApplicationRecord
  belongs_to :account
  validates :firstname, :lastname, :age, presence: true
end
```

Here is an example of designing a model that updates both Account and Profile at the same time, using `ActiveRecordCompose::Model`.

```ruby
class UserRegistration < ActiveRecordCompose::Model
  def initialize
    @account = Account.new
    @profile = @account.build_profile

    super()  # Don't forget to call `super()`
             # RuboCop's Lint/MissingSuper cop assists in addressing this.

    models << account << profile
    # Alternatively, it can also be written as follows:
    #     models.push(account)
    #     models.push(profile)
  end

  # Attribute declarations using ActiveModel::Attributes are supported.
  attribute :terms_of_service, :boolean

  # You can provide validation definitions limited to UserRegistration.
  # Instead of directly defining validations for Account or Profile, such
  # as `on: :create` in the context, the model itself explains the context.
  validates :terms_of_service, presence: true
  validates :email, confirmation: true

  # You can provide callback definitions limited to UserRegistration.
  # For example, if this is written directly in the AR model, you need to consider
  # callback control for data generation during tests and other situations.
  after_commit :send_email_message

  # UserRegistration behaves as if it has attributes like email, name, and age
  # For example, `email` is delegated to `account.email`,
  # and `email=` is delegated to `account.email=`.
  delegate_attribute :name, :email, to: :account
  delegate_attribute :firstname, :lastname, :age, to: :profile

  private

  attr_reader :account, :profile

  def send_email_message
    SendEmailConfirmationJob.perform_later(account)
  end
end
```

The above model is used as follows.

```ruby
registration = UserRegistration.new

# Atomically update Account and Profile.
registration.update!(
  name: "foo",
  email: "bar@example.com",
  firstname: "taro",
  lastname: "yamada",
  age: 18,
  email_confirmation: "bar@example.com",
  terms_of_service: true,
)
```

By executing `save`, you can simultaneously update multiple models added to `models`. Furthermore, the save operation is performed within a database transaction, ensuring atomic processing.

```ruby
user_registration.save  # Atomically update Account and Profile.
                        # In case of failure, a false value is returned.
user_registration.save! # With the bang method,
                        # an exception is raised in case of failure.
```

### `delegate_attribute`

In many cases, the composed models have attributes that need to be assigned before saving. `ActiveRecordCompose::Model` provides `delegate_attribute`, allowing transparent access to those attributes."

```ruby
  # UserRegistration behaves as if it has attributes like email, name, and age
  # For example, `email` is delegated to `account.email`,
  # and `email=` is delegated to `account.email=`.
  delegate_attribute :name, :email, to: :account
  delegate_attribute :firstname, :lastname, :age, to: :profile
```

Attributes defined with `.delegate_attribute` can be accessed through `#attributes` in the same way as the original attributes defined with `.attribute`.

```ruby
registration = UserRegistration.new
registration.name = "foo"
registration.terms_of_service = true

# Not only the email_confirmation defined with attribute,
# but also the attributes defined with delegate_attribute are included.
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

### Promotion to model from AR-model errors

When saving a composed model with `#save`, models that are not valid with `#valid?` will obviously not be saved. As a result, the #errors information can be accessed from `ActiveRecordCompose::Model`.

```ruby
user_registration = UserRegistration.new
user_registration.email = "foo@example.com"
user_registration.email_confirmation = "BAZ@example.com"
user_registration.age = 18
user_registration.terms_of_service = true

user_registration.save
#=> false

user_registration.errors.to_a
# => [
#   "Name can't be blank",
#   "Firstname can't be blank",
#   "Lastname can't be blank",
#   "Email confirmation doesn't match Email"
# ]
```

### I18n

When the `#save!` operation raises an `ActiveRecord::RecordInvalid` exception, it is necessary to have pre-existing locale definitions in order to construct i18n information correctly.
The specific keys required are `activemodel.errors.messages.record_invalid` or `errors.messages.record_invalid`.

(Replace `en` as appropriate in the context.)

```yaml
en:
  activemodel:
    errors:
      messages:
        record_invalid: 'Validation failed: %{errors}'
```

Alternatively, the following definition is also acceptable:

```yaml
en:
  errors:
    messages:
      record_invalid: 'Validation failed: %{errors}'
```

## Advanced Usage

### `destroy` option

By adding to the models array while specifying destroy: true, you can perform a delete instead of a save on the model at #save time.

```ruby
class AccountResignation < ActiveRecordCompose::Model
  def initialize(account)
    @account = account
    @profile = account.profile || account.build_profile
    super()
    models.push(account)
    models.push(profile, destroy: true)
  end

  before_save :set_resigned_at

  private

  attr_reader :account, :profile

  def set_resigned_at
    account.resigned_at = Time.zone.now
  end
end
```
```ruby
account = Account.last

account.resigned_at.present?  #=> nil
account.profile.blank?        #=> false

account_resignation = AccountResignation.new(account)
account_resignation.save!

account.reload
account.resigned_at.present?  #=> Tue, 02 Jan 2024 22:58:01.991008870 JST +09:00
account.profile.blank?        #=> true
```

Conditional destroy (or save) can be written like this.

```ruby
class AccountRegistration < ActiveRecordCompose::Model
  def initialize(account)
    @account = account
    @profile = account.profile || account.build_profile
    super()
    models.push(account)

    # destroy if all blank, otherwise save.
    models.push(profile, destroy: :profile_field_is_blank?)
    # Alternatively, it can also be written as follows:
    #     models.push(profile, destroy: -> { profile_field_is_blank? })
  end

  delegate_attribute :email, to: :account
  delegate_attribute :name, :age, to: :profile

  private

  attr_reader :account, :profile

  def profile_field_is_blank?
    firstname.blank? && lastname.blank? && age.blank?
  end
end
```

### Callback ordering by `#persisted?`

The behavior of `(before|after|around)_create` and `(before|after|around)_update` hooks depending on the evaluation result of `#persisted?`,
either the create-related callbacks or the update-related callbacks will be triggered.

```ruby
class ComposedModel < ActiveRecordCompose::Model
  # ...

  before_save { puts 'before_save called!' }
  before_create { puts 'before_create called!' }
  before_update { puts 'before_update called!' }
  after_save { puts 'after_save called!' }
  after_create { puts 'after_create called!' }
  after_update { puts 'after_update called!' }

  def persisted?
    # Override and return a boolish value depending on the state of the inner model.
    # For example, it could be transferred to the primary model to be manipulated.
    #
    #       # ex.)
    #       def persisted? = the_model.persisted?
    #
    true
  end
end
```

```ruby
# when `model.persisted?` returns `true`

model = ComposedModel.new

model.save # or `model.update` (the same callbacks will be triggered in all cases).

# before_save called!
# before_update called! # when persisted? is false, before_create hook is fired here instead.
# after_update called! # when persisted? is false, after_create hook is fired here instead.
# after_save called!
```

```ruby
# when `model.persisted?` returns `false`

model = ComposedModel.new

model.save # or `model.update` (the same callbacks will be triggered in all cases).

# before_save called!
# before_create called!
# after_create called!
# after_save called!
```

### `#save` with custom context option

The interface remains consistent with standard ActiveModel and ActiveRecord models, so the :context option works with #save.

```ruby
composed_model.valid?(:custom_context)

composed_model.save(context: :custom_context)
```

However, this may not be ideal from a design perspective.
If your application requires complex context-specific validations, consider separating models by context.

```ruby
class Account < ActiveRecord::Base
  validates :name, presence: true
  validates :email, presence: true
  validates :email, format: { with: /\.edu\z/ }, on: :education
end

class Registration < ActiveRecordCompose::Model
  def initialize(attributes = {})
    models.push(@account = Account.new)
    super(attributes)
  end

  attribute :accept, :boolean
  validates :accept, presence: true, on: :education

  delegate_attribute :name, :email, to: :account

  private

  attr_reader :account
end
```
```ruby
r = Registration.new(name: 'foo', email: 'example@example.com', accept: false)
r.valid?
=> true

r.valid?(:education)
=> false
r.errors.map { [_1.attribute, _1.type] }
=> [[:email, :invalid], [:accept, :blank]]

r.email = 'example@example.edu'
r.accept = true

r.valid?(:education)
=> true
r.save(context: :education)
=> true
```

## Sample application as an example

With Github Codespaces, it can also be run directly in the browser. Naturally, a local environment is also possible.

- https://github.com/hamajyotan/active_record_compose-example

## Links

- [Document from YARD](https://hamajyotan.github.io/active_record_compose/)
- [Smart way to update multiple models simultaneously in Rails](https://dev.to/hamajyotan/smart-way-to-update-multiple-models-simultaneously-in-rails-51b6)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/hamajyotan/active_record_compose. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/hamajyotan/active_record_compose/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ActiveRecord::Compose project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/hamajyotan/active_record_compose/blob/main/CODE_OF_CONDUCT.md).

