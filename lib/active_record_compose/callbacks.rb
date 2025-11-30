# frozen_string_literal: true

module ActiveRecordCompose
  # Provides hooks into the life cycle of an ActiveRecordCompose model,
  # allowing you to insert custom logic before or after changes to the object's state.
  #
  # The callback flow generally follows the same structure as Active Record:
  #
  # * `before_validation`
  # * `after_validation`
  # * `before_save`
  # * `before_create` (or `before_update` for update operations)
  # * `after_create` (or `after_update` for update operations)
  # * `after_save`
  # * `after_commit` (or `after_rollback` when the transaction is rolled back)
  #
  module Callbacks
    extend ActiveSupport::Concern
    include ActiveModel::Validations::Callbacks

    included do
      # @!method self.before_save(*args, &block)
      #   Registers a callback to be called before a model is saved.

      # @!method self.around_save(*args, &block)
      #   Registers a callback to be called around the save of a model.

      # @!method self.after_save(*args, &block)
      #   Registers a callback to be called after a model is saved.

      define_model_callbacks :save

      # @!method self.before_create(*args, &block)
      #   Registers a callback to be called before a model is created.

      # @!method self.around_create(*args, &block)
      #   Registers a callback to be called around the creation of a model.

      # @!method self.after_create(*args, &block)
      #   Registers a callback to be called after a model is created.

      define_model_callbacks :create

      # @!method self.before_update(*args, &block)
      #   Registers a callback to be called before a model is updated.

      # @!method self.around_update(*args, &block)
      #   Registers a callback to be called around the update of a model.

      # @!method self.after_update(*args, &block)
      #   Registers a callback to be called after a update is updated.
      define_model_callbacks :update
    end

    private

    # @private
    # Evaluate while firing callbacks such as `before_save` `after_save`
    # before and after block evaluation.
    #
    def with_callbacks(&block) = run_callbacks(:save) { run_callbacks(callback_context, &block) }

    # @private
    # Returns the symbol representing the callback context, which is `:create` if the record
    # is new, or `:update` if it has been persisted.
    #
    # @return [:create, :update] either `:create` if not persisted, or `:update` if persisted
    def callback_context = persisted? ? :update : :create
  end
end
