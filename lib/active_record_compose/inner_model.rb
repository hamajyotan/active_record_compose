# frozen_string_literal: true

require 'active_support/core_ext/object'

module ActiveRecordCompose
  class InnerModel
    # @param model [Object] the model instance.
    # @param destroy [Boolean] given true, destroy model.
    # @param destroy [Proc] when proc returning true, destroy model.
    # @param if [Proc] evaluation result is false, it will not be included in the renewal.
    def initialize(model, destroy: false, if: nil)
      @model = model
      @destroy_context_type = destroy
      @if_option = binding.local_variable_get(:if)
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

    # Returns a boolean indicating whether or not to exclude the user from the update.
    #
    # @return [Boolean] if true, exclude from update.
    def ignore?
      i = if_option
      if i.nil?
        false
      elsif i.arity == 0
        # @type var i: ^() -> bool
        !i.call
      else
        # @type var i: ^(_ARLike) -> bool
        !i.call(model)
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
      return false unless model == other.model

      true
    end

    protected

    attr_reader :model

    private

    attr_reader :destroy_context_type, :if_option

    # @private
    # steep:ignore:start
    module PackagePrivate
      refine InnerModel do
        # @private
        # Returns a model instance of raw, but it should
        # be noted that application developers are not expected to use this interface.
        #
        # @return [Object] raw model instance
        def __raw_model = model
      end
    end
    # steep:ignore:end
  end
end
