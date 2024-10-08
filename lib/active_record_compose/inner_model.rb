# frozen_string_literal: true

require 'active_support/core_ext/object'

module ActiveRecordCompose
  class InnerModel
    # @param model [Object] the model instance.
    # @param destroy [Boolean] given true, destroy model.
    # @param destroy [Proc] when proc returning true, destroy model.
    def initialize(model, destroy: false)
      @model = model
      @destroy_context_type = destroy
    end

    delegate :errors, to: :model

    # Determines whether to save or delete the target object.
    # Depends on the `destroy` value of the InnerModel object initialization option.
    #
    # On the other hand, there are values `mark_for_destruction` and `marked_for_destruction?` in ActiveRecord.
    # However, these values are not substituted here.
    # These values only work if the `autosave` option is enabled for the parent model,
    # and are not appropriate for other cases.
    #
    # @return [Boolean] returns true on destroy, false on save.
    def destroy_context?
      d = destroy_context_type
      if d.is_a?(Proc)
        if d.arity == 0
          # @type var d: ^() -> bool
          !!d.call
        else
          # @type var d: ^(_ARLike) -> bool
          !!d.call(model)
        end
      else
        !!d
      end
    end

    # Execute save or destroy. Returns true on success, false on failure.
    # Whether save or destroy is executed depends on the value of `#destroy_context?`.
    #
    # @return [Boolean] returns true on success, false on failure.
    def save = destroy_context? ? model.destroy : model.save

    # Execute save or destroy. Unlike #save, an exception is raises on failure.
    # Whether save or destroy is executed depends on the value of `#destroy_context?`.
    #
    def save! = destroy_context? ? model.destroy! : model.save!

    # @return [Boolean]
    def invalid? = destroy_context? ? false : model.invalid?

    # @return [Boolean]
    def valid? = !invalid?

    # Returns true if equivalent.
    #
    # @param [Object] other
    # @return [Boolean]
    def ==(other)
      return false unless self.class == other.class
      return false unless __raw_model == other.__raw_model # steep:ignore

      true
    end

    # @private
    # Returns a model instance of raw, but it should
    # be noted that application developers are not expected to use this interface.
    #
    # @return [Object] raw model instance
    def __raw_model = model

    private

    attr_reader :model, :destroy_context_type
  end
end
