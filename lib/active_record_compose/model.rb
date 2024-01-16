# frozen_string_literal: true

require 'active_record_compose/delegate_attribute'
require 'active_record_compose/inner_model_collection'

module ActiveRecordCompose
  class Model
    include ActiveModel::Model
    include ActiveModel::Validations::Callbacks
    include ActiveModel::Attributes
    include ActiveRecord::Transactions

    include ActiveRecordCompose::DelegateAttribute

    define_model_callbacks :save
    define_model_callbacks :create
    define_model_callbacks :update

    validate :validate_models

    def initialize(attributes = {})
      super(attributes)
    end

    # Save the models that exist in models.
    # Returns false if any of the targets fail, true if all succeed.
    #
    # The save is performed within a single transaction.
    #
    # @return [Boolean] returns true on success, false on failure.
    def save
      return false if invalid?

      save_in_transaction { save_models(bang: false) }
    end

    # Save the models that exist in models.
    # Unlike #save, an exception is raises on failure.
    #
    # Saving, like `#save`, is performed within a single transaction.
    #
    def save!
      valid? || raise_validation_error

      save_in_transaction { save_models(bang: true) } || raise_on_save_error
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

      save_in_transaction { run_callbacks(:create) { save_models(bang: false) } }
    end

    # Behavior is same to `#create`, but raises an exception prematurely on failure.
    #
    def create!(attributes = {})
      assign_attributes(attributes)
      valid? || raise_validation_error

      save_in_transaction { run_callbacks(:create) { save_models(bang: true) } } || raise_on_save_error
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

      save_in_transaction { run_callbacks(:update) { save_models(bang: false) } }
    end

    # Behavior is same to `#update`, but raises an exception prematurely on failure.
    #
    def update!(attributes = {})
      assign_attributes(attributes)
      valid? || raise_validation_error

      save_in_transaction { run_callbacks(:update) { save_models(bang: true) } } || raise_on_save_error
    end

    private

    def models = @__models ||= ActiveRecordCompose::InnerModelCollection.new

    def wrapped_models = models.__each_by_wrapped

    def validate_models = wrapped_models.select { _1.invalid? }.each { errors.merge!(_1) }

    def save_in_transaction(...)
      run_callbacks(:commit) do
        result = ::ActiveRecord::Base.transaction do
          raise ActiveRecord::Rollback unless run_callbacks(:save, ...)

          true
        end
        result.present?
      rescue StandardError
        run_callbacks :rollback
        raise
      end.present?
    end

    def save_models(bang:) = wrapped_models.all? { bang ? _1.save! : _1.save }

    def raise_validation_error = raise ActiveRecord::RecordInvalid, self

    def raise_on_save_error = raise ActiveRecord::RecordNotSaved.new(raise_on_save_error_message, self)

    def raise_on_save_error_message = 'Failed to save the model.'
  end
end
