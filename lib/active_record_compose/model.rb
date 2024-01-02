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

    def create(attributes = {})
      assign_attributes(attributes)
      return false if invalid?

      save_in_transaction { run_callbacks(:save) { run_callbacks(:create) { save_models } } }
    end

    def create!(attributes = {})
      create(attributes) || raise(error_class_on_save_error.new('Failed to create the model.', self))
    end

    def update(attributes = {})
      assign_attributes(attributes)
      return false if invalid?

      save_in_transaction { run_callbacks(:save) { run_callbacks(:update) { save_models } } }
    end

    def update!(attributes = {})
      update(attributes) || raise(error_class_on_save_error.new('Failed to update the model.', self))
    end

    private

    def models = @models ||= ActiveRecordCompose::InnerModelCollection.new

    def validate_models = models.select { _1.invalid? }.each { errors.merge!(_1) }

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

    def save_models = models.all? { _1.save! }
  end
end
