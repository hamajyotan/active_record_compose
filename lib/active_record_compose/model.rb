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

    # for ActiveRecord::Transactions
    class << self
      def connection = ActiveRecord::Base.connection
      __skip__ = def composite_primary_key? = false
    end

    def initialize(attributes = {})
      __skip__ = super(attributes)
    end

    # Save the models that exist in models.
    # Returns false if any of the targets fail, true if all succeed.
    #
    # The save is performed within a single transaction.
    #
    # @return [Boolean] returns true on success, false on failure.
    def save
      with_transaction_returning_status do
        return false if invalid?

        save_with_context(bang: false)
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
      with_transaction_returning_status do
        valid? || raise_validation_error

        save_with_context(bang: true) || raise_on_save_error
      end
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
      with_callback_context(:create) { save }
    end

    # Behavior is same to `#create`, but raises an exception prematurely on failure.
    #
    def create!(attributes = {})
      assign_attributes(attributes)
      with_callback_context(:create) { save! }
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
      with_callback_context(:update) { save }
    end

    # Behavior is same to `#update`, but raises an exception prematurely on failure.
    #
    def update!(attributes = {})
      assign_attributes(attributes)
      with_callback_context(:update) { save! }
    end

    # for ActiveRecord::Transactions
    __skip__ = def id = nil

    # for ActiveRecord::Transactions
    __skip__ = def trigger_transactional_callbacks? = true

    # for ActiveRecord::Transactions
    __skip__ = def restore_transaction_record_state(_force_restore_state) = nil

    private

    def models = @__models ||= ActiveRecordCompose::InnerModelCollection.new

    def wrapped_models = models.__each_by_wrapped

    def with_callback_context(callback_context)
      original = @__callback_context
      @__callback_context = callback_context
      yield
    rescue StandardError
      @__callback_context = original
    end

    def validate_models = wrapped_models.select { _1.invalid? }.each { errors.merge!(_1) }

    def save_with_context(bang:)
      run_callbacks(:save) do
        if @__callback_context
          run_callbacks(@__callback_context) { save_models(bang:) }
        else
          save_models(bang:)
        end
      end
    end

    def save_models(bang:) = wrapped_models.all? { bang ? _1.save! : _1.save }

    def raise_validation_error = raise ActiveRecord::RecordInvalid, self

    def raise_on_save_error = raise ActiveRecord::RecordNotSaved.new(raise_on_save_error_message, self)

    def raise_on_save_error_message = 'Failed to save the model.'
  end
end
