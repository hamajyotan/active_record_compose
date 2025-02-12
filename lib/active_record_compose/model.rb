# frozen_string_literal: true

require 'active_record_compose/composed_collection'
require 'active_record_compose/delegate_attribute'
require 'active_record_compose/transaction_support'

module ActiveRecordCompose
  using ComposedCollection::PackagePrivate

  class Model
    include ActiveModel::Model
    include ActiveModel::Validations::Callbacks
    include ActiveModel::Attributes

    include ActiveRecordCompose::DelegateAttribute
    include ActiveRecordCompose::TransactionSupport

    define_model_callbacks :save
    define_model_callbacks :create
    define_model_callbacks :update

    validate :validate_models

    def initialize(attributes = {})
      super
    end

    # Save the models that exist in models.
    # Returns false if any of the targets fail, true if all succeed.
    #
    # The save is performed within a single transaction.
    #
    # Options like `:validate` and `:context` are not accepted as arguments.
    # The need for such values indicates that operations from multiple contexts are being handled.
    # However, if the contexts are different, it is recommended to separate them into different model definitions.
    #
    # @return [Boolean] returns true on success, false on failure.
    def save
      return false if invalid?

      with_transaction_returning_status do
        with_callbacks { save_models(bang: false) }
      rescue ActiveRecord::RecordInvalid
        false
      end
    end

    # Save the models that exist in models.
    # Unlike #save, an exception is raises on failure.
    #
    # Saving, like `#save`, is performed within a single transaction.
    #
    # Options like `:validate` and `:context` are not accepted as arguments.
    # The need for such values indicates that operations from multiple contexts are being handled.
    # However, if the contexts are different, it is recommended to separate them into different model definitions.
    #
    def save!
      valid? || raise_validation_error

      with_transaction_returning_status do
        with_callbacks { save_models(bang: true) }
      end || raise_on_save_error
    end

    # Assign attributes and save.
    #
    # @return [Boolean] returns true on success, false on failure.
    def update(attributes = {})
      assign_attributes(attributes)
      save
    end

    # Behavior is same to `#update`, but raises an exception prematurely on failure.
    #
    def update!(attributes = {})
      assign_attributes(attributes)
      save!
    end

    # Returns true if model is persisted.
    #
    # By overriding this definition, you can control the callbacks that are triggered when a save is made.
    # For example, returning false will trigger before_create, around_create and after_create,
    # and returning true will trigger before_update, around_update and after_update.
    #
    # @return [Boolean] returns true if model is persisted.
    def persisted? = super

    private

    def models = @__models ||= ActiveRecordCompose::ComposedCollection.new(self)

    def validate_models
      models.__wrapped_models.lazy.select { _1.invalid? }.each { errors.merge!(_1) }
    end

    def with_callbacks(&block) = run_callbacks(:save) { run_callbacks(callback_context, &block) }

    def callback_context = persisted? ? :update : :create

    def save_models(bang:)
      models.__wrapped_models.all? { bang ? _1.save! : _1.save }
    end

    def raise_validation_error = raise ActiveRecord::RecordInvalid, self

    def raise_on_save_error = raise ActiveRecord::RecordNotSaved.new(raise_on_save_error_message, self)

    def raise_on_save_error_message = 'Failed to save the model.'
  end
end
