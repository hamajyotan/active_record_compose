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

    class_attribute :error_class_on_save_error, instance_writer: false, default: ActiveRecordCompose::RecordNotSaved

    define_model_callbacks :save
    define_model_callbacks :create
    define_model_callbacks :update

    validate :validate_models

    def initialize(attributes = {})
      super(attributes)
    end

    def save
      return false if invalid?

      save_in_transaction { run_callbacks(:save) { save_models } }
    end

    def save! = save || raise(error_class_on_save_error.new('Failed to save the model.', self))

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

      save_in_transaction { run_callbacks(:save) { run_callbacks(:create) { save_models } } }
    end

    # Behavior is same to `#create`, but raises an exception prematurely on failure.
    #
    def create!(attributes = {})
      create(attributes) || raise(error_class_on_save_error.new('Failed to create the model.', self))
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

      save_in_transaction { run_callbacks(:save) { run_callbacks(:update) { save_models } } }
    end

    # Behavior is same to `#update`, but raises an exception prematurely on failure.
    #
    def update!(attributes = {})
      update(attributes) || raise(error_class_on_save_error.new('Failed to update the model.', self))
    end

    private

    def models = @__models ||= ActiveRecordCompose::InnerModelCollection.new

    def wrapped_models = models.__each_by_wrapped

    def validate_models = wrapped_models.select { _1.invalid? }.each { errors.merge!(_1) }

    def save_in_transaction
      run_callbacks(:commit) do
        result = ::ActiveRecord::Base.transaction do
          raise ActiveRecord::Rollback unless yield

          true
        end
        result.present?
      rescue StandardError
        run_callbacks :rollback
        raise
      end.present?
    end

    def save_models = wrapped_models.all? { _1.save! }
  end
end
