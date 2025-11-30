# frozen_string_literal: true

require_relative "callbacks"
require_relative "composed_collection"

module ActiveRecordCompose
  using ComposedCollection::PackagePrivate

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
    # @param options [Hash] parameters.
    # @option options [Boolean] :validate Whether to run validations.
    #   This option is intended for internal use only.
    #   Users should avoid explicitly passing <tt>validate: false</tt>,
    #   as skipping validations can lead to unexpected behavior.
    # @return [Boolean] returns true on success, false on failure.
    def save(**options)
      with_callbacks { save_models(**options, bang: false) }
    rescue ActiveRecord::RecordInvalid
      false
    end

    # Behavior is same to {#save}, but raises an exception prematurely on failure.
    #
    # @see #save
    # @raise ActiveRecord::RecordInvalid
    # @raise ActiveRecord::RecordNotSaved
    def save!(**options)
      with_callbacks { save_models(**options, bang: true) } || raise_on_save_error
    end

    # Assign attributes and {#save}.
    #
    # @param [Hash<String, Object>] attributes
    #   new attributes.
    # @see #save
    # @return [Boolean] returns true on success, false on failure.
    def update(attributes)
      assign_attributes(attributes)
      save
    end

    # Behavior is same to {#update}, but raises an exception prematurely on failure.
    #
    # @param [Hash<String, Object>] attributes
    #   new attributes.
    # @see #save
    # @see #update
    # @raise ActiveRecord::RecordInvalid
    # @raise ActiveRecord::RecordNotSaved
    def update!(attributes)
      assign_attributes(attributes)
      save!
    end

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

    private

    # @private
    def save_models(bang:, **options)
      models.__wrapped_models.all? do |model|
        if bang
          model.save!(**options, validate: false)
        else
          model.save(**options, validate: false)
        end
      end
    end

    # @private
    def raise_on_save_error = raise ActiveRecord::RecordNotSaved.new(raise_on_save_error_message, self)

    # @private
    def raise_on_save_error_message = "Failed to save the model."
  end
end
