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
    # @return [Boolean] returns true on success, false on failure.
    def save
      return false if invalid?

      with_transaction_returning_status do
        run_callbacks(:save) { save_models(bang: false) }
      rescue ActiveRecord::RecordInvalid
        false
      end
    end

    # Save the models that exist in models.
    # Unlike #save, an exception is raises on failure.
    #
    # Saving, like `#save`, is performed within a single transaction.
    #
    def save!
      valid? || raise_validation_error

      with_transaction_returning_status do
        run_callbacks(:save) { save_models(bang: true) }
      end || raise_on_save_error
    end

    # Behavior is same to `#save`, but `before_create` and `after_create` hooks fires.
    #
    #   class ComposedModel < ActiveRecordCompose::Model
    #     # ...
    #
    #     before_save { puts 'before_save called!' }
    #     before_create { puts 'before_create called!' }
    #     before_update { puts 'before_update called!' }
    #     after_save { puts 'after_save called!' }
    #     after_create { puts 'after_create called!' }
    #     after_update { puts 'after_update called!' }
    #   end
    #
    #   model = ComposedModel.new
    #
    #   model.save
    #   # before_save called!
    #   # after_save called!
    #
    #   model.create
    #   # before_save called!
    #   # before_create called!
    #   # after_create called!
    #   # after_save called!
    #
    def create(attributes = {})
      assign_attributes(attributes)
      return false if invalid?

      with_transaction_returning_status do
        with_callbacks(context: :create) { save_models(bang: false) }
      rescue ActiveRecord::RecordInvalid
        false
      end
    end

    # Behavior is same to `#create`, but raises an exception prematurely on failure.
    #
    def create!(attributes = {})
      assign_attributes(attributes)
      valid? || raise_validation_error

      with_transaction_returning_status do
        with_callbacks(context: :create) { save_models(bang: true) }
      end || raise_on_save_error
    end

    # Behavior is same to `#save`, but `before_update` and `after_update` hooks fires.
    #
    #   class ComposedModel < ActiveRecordCompose::Model
    #     # ...
    #
    #     before_save { puts 'before_save called!' }
    #     before_create { puts 'before_create called!' }
    #     before_update { puts 'before_update called!' }
    #     after_save { puts 'after_save called!' }
    #     after_create { puts 'after_create called!' }
    #     after_update { puts 'after_update called!' }
    #   end
    #
    #   model = ComposedModel.new
    #
    #   model.save
    #   # before_save called!
    #   # after_save called!
    #
    #   model.update
    #   # before_save called!
    #   # before_update called!
    #   # after_update called!
    #   # after_save called!
    #
    def update(attributes = {})
      assign_attributes(attributes)
      return false if invalid?

      with_transaction_returning_status do
        with_callbacks(context: :update) { save_models(bang: false) }
      rescue ActiveRecord::RecordInvalid
        false
      end
    end

    # Behavior is same to `#update`, but raises an exception prematurely on failure.
    #
    def update!(attributes = {})
      assign_attributes(attributes)
      valid? || raise_validation_error

      with_transaction_returning_status do
        with_callbacks(context: :update) { save_models(bang: true) }
      end || raise_on_save_error
    end

    private

    def models = @__models ||= ActiveRecordCompose::ComposedCollection.new(self)

    def validate_models
      models.__wrapped_models.select { _1.invalid? }.each { errors.merge!(_1) }
    end

    def with_callbacks(context:, &block)
      run_callbacks(:save) { run_callbacks(context, &block) }
    end

    def save_models(bang:)
      models.__wrapped_models.all? { bang ? _1.save! : _1.save }
    end

    def raise_validation_error = raise ActiveRecord::RecordInvalid, self

    def raise_on_save_error = raise ActiveRecord::RecordNotSaved.new(raise_on_save_error_message, self)

    def raise_on_save_error_message = 'Failed to save the model.'
  end
end
