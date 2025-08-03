# frozen_string_literal: true

require_relative "callbacks"
require_relative "composed_collection"

module ActiveRecordCompose
  using ComposedCollection::PackagePrivate

  # @private
  module Persistence
    extend ActiveSupport::Concern
    include ActiveRecordCompose::Callbacks

    # Save the models that exist in models.
    # Returns false if any of the targets fail, true if all succeed.
    #
    # The save is performed within a single transaction.
    #
    # Only the `:validate` option takes effect as it is required internally.
    # However, we do not recommend explicitly specifying `validate: false` to skip validation.
    # Additionally, the `:context` option is not accepted.
    # The need for such a value indicates that operations from multiple contexts are being processed.
    # If the contexts differ, we recommend separating them into different model definitions.
    #
    # @return [Boolean] returns true on success, false on failure.
    def save(**options)
      with_callbacks { save_models(**options, bang: false) }
    rescue ActiveRecord::RecordInvalid
      false
    end

    # Save the models that exist in models.
    # Unlike #save, an exception is raises on failure.
    #
    # Saving, like `#save`, is performed within a single transaction.
    #
    # Only the `:validate` option takes effect as it is required internally.
    # However, we do not recommend explicitly specifying `validate: false` to skip validation.
    # Additionally, the `:context` option is not accepted.
    # The need for such a value indicates that operations from multiple contexts are being processed.
    # If the contexts differ, we recommend separating them into different model definitions.
    #
    def save!(**options)
      with_callbacks { save_models(**options, bang: true) } || raise_on_save_error
    end

    # Assign attributes and save.
    #
    # @return [Boolean] returns true on success, false on failure.
    def update(attributes)
      assign_attributes(attributes)
      save
    end

    # Behavior is same to `#update`, but raises an exception prematurely on failure.
    #
    def update!(attributes)
      assign_attributes(attributes)
      save!
    end

    private

    def save_models(bang:, **options)
      models.__wrapped_models.all? do |model|
        if bang
          model.save!(**options, validate: false)
        else
          model.save(**options, validate: false)
        end
      end
    end

    def raise_on_save_error = raise ActiveRecord::RecordNotSaved.new(raise_on_save_error_message, self)

    def raise_on_save_error_message = "Failed to save the model."
  end
end
