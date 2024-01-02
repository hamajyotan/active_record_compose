# ActiveRecordCompose

activermodel (activerecord) form object pattern.

![CI](https://github.com/hamajyotan/active_record_compose/workflows/CI/badge.svg)

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

### ActiveRecordCompose::Model basic

It wraps AR objects or equivalent models to provide unified operation.
For example, the following cases are supported

#### Context-specific callbacks.

A callback is useful to define some processing before or after a save in a particular model.
However, if a callback is written directly in the AR model, it is necessary to consider the case where the model is updated in other contexts.
In particular, if you frequently create with test data, previously unnecessary processing will be called at every point of creation.
In addition to cost, the more complicated the callbacks you write, the more difficult it will be to create even a single test data.
If the callbacks are written in a class that inherits from `ApplicationRecordCompose::Model`, the AR model itself will not be polluted, and the context can be limited.

```ruby
class AccountRegistration < ActiveRecordCompose::Model
  def initialize(account = Account.new, attributes = {})
    @account = account
    super(attributes)

    # By including AR instance in models, AR instance itself is saved when this model is saved.
    models.push(account)
  end

  # By delegating these to the AR instance,
  # For example, this model itself can be given directly as an argument to form_with, and it will behave as if it were an instance of the model.
  delegate :id, :persisted?, to: :account

  # Defines an attribute of the same name that delegates to account#name and account#email
  delegate_attribute :name, :email, to: :account

  # You can only define post-processing if you update through this model.
  # If this is written directly into the AR model, for example, it would be necessary to consider a callback control for each test data generation.
  after_commit :try_send_email_message

  private

  attr_reader :account

  def try_send_email_message
    SendEmailConfirmationJob.perform_later(account)
  end
end
```

#### Validation limited to a specific context.

Validates are basically fired in all cases where the model is manipulated. To avoid this, use `on: :create`, etc. to make it work only in specific cases.
and so on to work only in specific cases. This allows you to create context-sensitive validations for the same model operation.
However, this is the first step in making the model more and more complex. You will have to go around with `update(context: :foo)`
In some cases, you may have to go around with the context option, such as `update(context: :foo)` everywhere.
By writing validates in a class that extends `ApplicationRecordCompose::Model`, you can define context-specific validation without polluting the AR model itself.

```ruby
class AccountRegistration < ActiveRecordCompose::Model
  def initialize(account = Account.new, attributes = {})
    @account = account
    super(attributes)
    models.push(account)
  end

  delegate :id, :persisted?, to: :account
  delegate_attribute :name, :email, to: :account

  # Only if this model is used, also check the validity of the domain
  before_validation :require_valid_domain

  private

  attr_reader :account

  # Validity of the domain part of the e-mail address is also checked only when registering an account.
  def require_valid_domain
    e = ValidEmail2::Address.new(email.to_s)
    unless e.valid?
      errors.add(:email, :invalid_format)
      return
    end
    unless e.valid_mx?
      errors.add(:email, :invalid_domain)
    end
  end
end
```

```ruby
account = Account.new(name: 'new account', email: 'foo@example.com')
account.valid?  #=> true

account_registration = AccountRegistration.new(name: 'new account', email: 'foo@example.com')
account_registration.valid?  #=> false
```

#### updating multiple models at the same time.

In an AR model, you can add, for example, `autosave: true` or `accepts_nested_attributes_for` to an association to update the related models at the same time.
There are ways to update related models at the same time. The operation is safe because it is transactional.
`ApplicationRecordCompose::Model` has an internal array called models. By adding an AR object to this models array
By adding an AR object to the models, the object stored in the models provides an atomic update operation via #save.

```ruby
class AccountRegistration < ActiveRecordCompose::Model
  def initialize(account = Account.new, profile = account.build_profile, attributes = {})
    @account = account
    @profile = profile
    super(attributes)
    models << account << profile
  end

  delegate :id, :persisted?, to: :account
  delegate_attribute :name, :email, to: :account
  delegate_attribute :firstname, :lastname, :age, to: :profile

  private

  attr_reader :account, :profile
end
```

```ruby
Account.count  #=> 0
Profile.count  #=> 0

account_registration =
  AccountRegistration.new(
    name: 'foo',
    email: 'foo@example.com',
    firstname: 'bar',
    lastname: 'baz',
    age: 36,
  )
account_registration.save!

Account.count  #=> 1
Profile.count  #=> 1
```

By adding to the `models` array while specifying `context: :destroy`, you can perform a delete instead of a save on the model at `#save` time.

```ruby
class AccountResignation < ActiveRecordCompose::Model
  def initialize(account)
    @account = account
    @profile = account.profile  # Suppose that Account has_one Profile.
    models.push(account)
    models.push(profile, context: :destroy)
  end

  attr_reader :account, :profile

  before_save :set_resigned_at

  private

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

### `delegate_attribute`

It provides a macro description that expresses access to the attributes of the AR model through delegation.

```ruby
class AccountRegistration < ActiveRecordCompose::Model
  def initialize(account)
    @account = account
    super(attributes)
    models.push(account)
  end

  attribute :original_attribute, :string, default: 'qux'
  delegate_attribute :name, to: :account

  private

  attr_reader :account
end
```

```ruby
account = Account.new
account.name = 'foo'

registration = AccountRegistration.new(account)
registration.name  #=> 'foo'

registration.name = 'bar'
account.name  #=> 'bar'
```

Overrides `#attributes`, merging attributes defined with `delegate_attribute` in addition to the original attributes.

```
account.attributes  #=> {'original_attribute' => 'qux', 'name' => 'bar'}
```

### Callback ordering by `#save`, `#create` and `#update`.

Sometimes, multiple AR objects are passed to the models in the arguments.
It is not strictly possible to distinguish between create and update operations, regardless of the state of `#persisted?`.
Therefore, control measures such as separating callbacks with `after_create` and `after_update` based on the `#persisted?` of AR objects are left to the discretion of the user,
rather than being determined by the state of the AR objects themselves.

```ruby
class ComposedModel < ActiveRecordCompose::Model
  # ...

  before_save { puts 'before_save called!' }
  before_create { puts 'before_create called!' }
  before_update { puts 'before_update called!' }
  after_save { puts 'after_save called!' }
  after_create { puts 'after_create called!' }
  after_update { puts 'after_update called!' }
end
```

```ruby
model = ComposedModel.new

model.save
# before_save called!
# after_save called!

model.create
# before_save called!
# before_create called!
# after_create called!
# after_save called!

model.update
# before_save called!
# before_update called!
# after_update called!
# after_save called!
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/hamajyotan/active_record_compose. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/hamajyotan/active_record_compose/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ActiveRecord::Compose project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/hamajyotan/active_record_compose/blob/main/CODE_OF_CONDUCT.md).
