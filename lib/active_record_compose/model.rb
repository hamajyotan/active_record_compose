# frozen_string_literal: true

require_relative "attributes"
require_relative "composed_collection"
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

    begin
      # @group Model Core

      # @!method self.delegate_attribute(*attributes, to:, allow_nil: false)
      #   Provides a method of attribute access to the encapsulated model.
      #
      #   It provides a way to access the attributes of the model it encompasses,
      #   allowing transparent access as if it had those attributes itself.
      #
      #   @param [Array<Symbol, String>] attributes
      #     attributes A variable-length list of attribute names to delegate.
      #   @param [Symbol, String] to
      #     The target object to which attributes are delegated (keyword argument).
      #   @param [Boolean] allow_nil
      #     allow_nil Whether to allow nil values. Defaults to false.
      #   @example Basic usage
      #     delegate_attribute :name, :email, to: :profile
      #   @example Allowing nil
      #     delegate_attribute :bio, to: :profile, allow_nil: true
      #   @see Module#delegate for similar behavior in ActiveSupport

      # @!method self.attribute_names
      #   Returns a array of attribute name.
      #   Attributes declared with {.delegate_attribute} are also merged.
      #
      #   @see #attribute_names
      #   @return [Array<String>] array of attribute name.

      # @!method attribute_names
      #   Returns a array of attribute name.
      #   Attributes declared with {.delegate_attribute} are also merged.
      #
      #       class Foo < ActiveRecordCompose::Base
      #         def initialize(attributes = {})
      #           @account = Account.new
      #           super
      #         end
      #
      #         attribute :confirmation, :boolean, default: false   # plain attribute
      #         delegate_attribute :name, to: :account              # delegated attribute
      #
      #         private
      #
      #         attr_reader :account
      #       end
      #
      #       Foo.attribute_names                                   # Returns the merged state of plain and delegated attributes
      #       # => ["confirmation" ,"name"]
      #
      #       foo = Foo.new
      #       foo.attribute_names                                   # Similar behavior for instance method version
      #       # => ["confirmation", "name"]
      #
      #   @see #attributes
      #   @return [Array<String>] array of attribute name.

      # @!method attributes
      #   Returns a hash with the attribute name as key and the attribute value as value.
      #   Attributes declared with {.delegate_attribute} are also merged.
      #
      #       class Foo < ActiveRecordCompose::Base
      #         def initialize(attributes = {})
      #           @account = Account.new
      #           super
      #         end
      #
      #         attribute :confirmation, :boolean, default: false   # plain attribute
      #         delegate_attribute :name, to: :account              # delegated attribute
      #
      #         private
      #
      #         attr_reader :account
      #       end
      #
      #       foo = Foo.new
      #       foo.name = "Alice"
      #       foo.confirmation = true
      #
      #       foo.attributes                                        # Returns the merged state of plain and delegated attributes
      #       # => { "confirmation" => true, "name" => "Alice" }
      #
      #   @return [Hash<String, Object>] hash with the attribute name as key and the attribute value as value.

      # @!method persisted?
      #   Returns true if model is persisted.
      #
      #   By overriding this definition, you can control the callbacks that are triggered when a save is made.
      #   For example, returning false will trigger before_create, around_create and after_create,
      #   and returning true will trigger {.before_update}, {.around_update} and {.after_update}.
      #
      #   @return [Boolean] returns true if model is persisted.
      #   @example
      #       # A model where persistence is always false
      #       class Foo < ActiveRecordCompose::Model
      #         before_save { puts "before_save called" }
      #         before_create { puts "before_create called" }
      #         before_update { puts "before_update called" }
      #         after_update { puts "after_update called" }
      #         after_create { puts "after_create called" }
      #         after_save { puts "after_save called" }
      #
      #         def persisted? = false
      #       end
      #
      #       # A model where persistence is always true
      #       class Bar < Foo
      #         def persisted? = true
      #       end
      #
      #       Foo.new.save!
      #       # before_save called
      #       # before_create called
      #       # after_create called
      #       # after_save called
      #
      #       Bar.new.save!
      #       # before_save called
      #       # before_update called
      #       # after_update called
      #       # after_save called

      # @endgroup

      # @group Validations

      # @!method valid?(context = nil)
      #   Runs all the validations and returns the result as true or false.
      #   @param context Validation context.
      #   @return [Boolean] true on success, false on failure.

      # @!method validate(context = nil)
      #   Alias for {#valid?}
      #   @see #valid? Validation context.
      #   @param context
      #   @return [Boolean] true on success, false on failure.

      # @!method validate!(context = nil)
      #   @see #valid?
      #   Runs all the validations within the specified context.
      #   no errors are found, raises `ActiveRecord::RecordInvalid` otherwise.
      #   @param context Validation context.
      #   @raise ActiveRecord::RecordInvalid

      # @!method errors
      #   Returns the `ActiveModel::Errors` object that holds all information about attribute error messages.
      #
      #   The `ActiveModel::Base` implementation itself,
      #   but also aggregates error information for objects stored in {#models} when validation is performed.
      #
      #       class Account < ActiveRecord::Base
      #         validates :name, :email, presence: true
      #       end
      #
      #       class AccountRegistration < ActiveRecordCompose::Model
      #         def initialize(attributes = {})
      #           @account = Account.new
      #           super(attributes)
      #           models << account
      #         end
      #
      #         attribute :confirmation, :boolean, default: false
      #         validates :confirmation, presence: true
      #
      #         private
      #
      #         attr_reader :account
      #       end
      #
      #       registration = AccountRegistration
      #       registration.valid?
      #       #=> false
      #
      #       # In addition to the model's own validation error information (`confirmation`), also aggregates
      #       # error information for objects stored in `account` (`name`, `email`) when validation is performed.
      #
      #       registration.errors.map { _1.attribute }  #=> [:name, :email, :confirmation]
      #
      #   @return [ActiveModel::Errors]

      # @endgroup

      # @group Persistences

      # @!method save(**options)
      #   Save the models that exist in models.
      #   Returns false if any of the targets fail, true if all succeed.
      #
      #   The save is performed within a single transaction.
      #
      #   Only the `:validate` option takes effect as it is required internally.
      #   However, we do not recommend explicitly specifying `validate: false` to skip validation.
      #   Additionally, the `:context` option is not accepted.
      #   The need for such a value indicates that operations from multiple contexts are being processed.
      #   If the contexts differ, we recommend separating them into different model definitions.
      #
      #   @params [Hash] Optional parameters.
      #   @option options [Boolean] :validate Whether to run validations.
      #     This option is intended for internal use only.
      #     Users should avoid explicitly passing <tt>validate: false</tt>,
      #     as skipping validations can lead to unexpected behavior.
      #   @return [Boolean] returns true on success, false on failure.

      # @!method save!(**options)
      #   Behavior is same to {#save}, but raises an exception prematurely on failure.
      #   @see #save
      #   @raise ActiveRecord::RecordInvalid
      #   @raise ActiveRecord::RecordNotSaved

      # @!method update(attributes)
      #   Assign attributes and {#save}.
      #
      #   @param [Hash<String, Object>] attributes
      #     new attributes.
      #   @see #save
      #   @return [Boolean] returns true on success, false on failure.

      # @!method update!(attributes)
      #   Behavior is same to {#update}, but raises an exception prematurely on failure.
      #
      #   @param [Hash<String, Object>] attributes
      #     new attributes.
      #   @see #save
      #   @see #update
      #   @raise ActiveRecord::RecordInvalid
      #   @raise ActiveRecord::RecordNotSaved

      # @endgroup

      # @group Callbacks

      # @!method self.before_save(*args, &block)
      #   Registers a callback to be called before a model is saved.

      # @!method self.around_save(*args, &block)
      #   Registers a callback to be called around the save of a model.

      # @!method self.after_save(*args, &block)
      #   Registers a callback to be called after a model is saved.

      # @!method self.before_create(*args, &block)
      #   Registers a callback to be called before a model is created.

      # @!method self.around_create(*args, &block)
      #   Registers a callback to be called around the creation of a model.

      # @!method self.after_create(*args, &block)
      #   Registers a callback to be called after a model is created.

      # @!method self.before_update(*args, &block)
      #   Registers a callback to be called before a model is updated.

      # @!method self.around_update(*args, &block)
      #   Registers a callback to be called around the update of a model.

      # @!method self.after_update(*args, &block)
      #   Registers a callback to be called after a update is updated.

      # @!method self.after_commit(*args, &block)
      #   Registers a block to be called after the transaction is fully committed.

      # @!method self.after_rollback(*args, &block)
      #   Registers a block to be called after the transaction is rolled back.

      # @endgroup
    end

    # @group Model Core

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

    # @endgroup
  end
end
