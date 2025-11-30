# frozen_string_literal: true

require_relative "attributes"
require_relative "composed_collection"
require_relative "inspectable"
require_relative "persistence"
require_relative "transaction_support"
require_relative "validations"

module ActiveRecordCompose
  # This is the core class of {ActiveRecordCompose}.
  #
  # By defining subclasses of this model, you can use ActiveRecordCompose functionality in your application.
  # It has the basic functionality of `ActiveModel::Model` and `ActiveModel::Attributes`,
  # and also provides aggregation of multiple models and atomic updates through transaction control.
  # @example Example of model registration.
  #     class AccountRegistration < ActiveRecordCompose::Model
  #       def initialize(account = Account.new, attributes = {})
  #         @account = account
  #         @profile = @account.build_profile
  #         models << account << profile
  #         super(attributes)
  #       end
  #
  #       attribute :register_confirmation, :boolean, default: false
  #       delegate_attribute :name, :email, to: :account
  #       delegate_attribute :firstname, :lastname, :age, to: :profile
  #
  #       validates :register_confirmation, presence: true
  #
  #       private
  #
  #       attr_reader :account, :profile
  #     end
  # @example Multiple model update once.
  #     registration = AccountRegistration.new
  #     registration.assign_attributes(
  #       name: "alice-in-wonderland",
  #       email: "alice@example.com",
  #       firstname: "Alice",
  #       lastname: "Smith",
  #       age: 24,
  #       register_confirmation: true
  #     )
  #
  #     registration.save!      # Register Account and Profile models at the same time.
  #     Account.count           # => (0 ->) 1
  #     Profile.count           # => (0 ->) 1
  # @example Attribute delegation.
  #     account = Account.new
  #     account.name = "foo"
  #
  #     registration = AccountRegistration.new(account)
  #     registration.name         # => "foo" (delegated)
  #     registration.name?        # => true  (delegated attribute method + `?`)
  #
  #     registration.name = "bar" # => updates account.name
  #     account.name              # => "bar"
  #     account.name?             # => true
  #
  #     registration.attributes   # => { "original_attribute" => "qux", "name" => "bar" }
  # @example Aggregate errors on invalid.
  #     registration = AccountRegistration.new
  #
  #     registration.name = "alice-in-wonderland"
  #     registration.firstname = "Alice"
  #     registration.age = 18
  #
  #     registration.valid?
  #     #=> false
  #
  #     # The error contents of the objects stored in models are aggregated.
  #     # For example, direct access to errors in Account#email.
  #     registration.errors[:email].to_a  # Account#email
  #     #=> ["can't be blank"]
  #
  #     # Of course, the validation defined for itself is also working.
  #     registration.errors[:register_confirmation].to_a
  #     #=> ["can't be blank"]
  #
  #     registration.errors.to_a
  #     #=> ["Email can't be blank", "Lastname can't be blank", "Register confirmation can't be blank"]
  class Model
    include ActiveModel::Model

    include ActiveRecordCompose::Attributes
    include ActiveRecordCompose::Persistence
    include ActiveRecordCompose::Validations
    include ActiveRecordCompose::TransactionSupport
    include ActiveRecordCompose::Inspectable

    def initialize(attributes = {})
      super
    end

    # Returns the ID value. This value is used when passing it to the `:model` option of `form_with`, etc.
    # Normally it returns nil, but it can be overridden to delegate to the containing model.
    #
    # @example Redefine the id method by delegating to the containing model
    #     class Foo < ActiveRecordCompose::Model
    #       def initialize(primary_model)
    #         @primary_model = primary_model
    #         # ...
    #       end
    #
    #       def id
    #         primary_model.id
    #       end
    #
    #       private
    #
    #       attr_reader :primary_model
    #     end
    #
    # @return [Object] ID value
    #
    def id = nil

    private

    # Returns a collection of model elements to encapsulate.
    # @example Adding models
    #   models << inner_model_a << inner_model_b
    #   models.push(inner_model_c)
    # @example `#push` can have `:destroy` `:if` options
    #   models.push(profile, destroy: :blank_profile?)
    #   models.push(profile, destroy: -> { blank_profile? })
    # @return [ActiveRecordCompose::ComposedCollection]
    #
    def models = @__models ||= ActiveRecordCompose::ComposedCollection.new(self)
  end
end
