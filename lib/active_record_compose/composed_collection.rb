# frozen_string_literal: true

require_relative "errors"
require_relative "wrapped_model"

module ActiveRecordCompose
  using WrappedModel::PackagePrivate

  # Object obtained by {ActiveRecordCompose::Model#models}.
  #
  # It functions as a collection that contains the object to be saved.
  class ComposedCollection
    include Enumerable

    def initialize(owner)
      @owner = owner
      @models = []
      @locked = false
    end

    # Enumerates model objects.
    #
    # @yieldparam [Object] model model instance
    # @return [Enumerator] when not block given.
    # @return [self] when block given, returns itself.
    def each
      return enum_for(:each) unless block_given?

      models.each { yield _1.__raw_model }
      self
    end

    # Appends model to collection.
    #
    # @param model [Object] model instance
    # @return [self] returns itself.
    def <<(model)
      raise LockedCollectionError.new("Collection is locked and cannot be changed.", owner) if locked?

      models << wrap(model, destroy: false)
      self
    end

    # Appends model to collection.
    #
    # @param model [Object] model instance
    # @param destroy [Boolean, Proc, Symbol] Controls whether the model should be destroyed.
    #   - Boolean: if `true`, the model will be destroyed.
    #   - Proc: the model will be destroyed if the proc returns `true`.
    #   - Symbol: sends the symbol as a method to `owner`; if the result is truthy, the model will be destroyed.
    # @param if [Proc, Symbol] Controls conditional inclusion in renewal.
    #   - Proc: the proc is called, and if it returns `false`, the model is excluded.
    #   - Symbol: sends the symbol as a method to `owner`; if the result is falsy, the model is excluded.
    # @return [self] returns itself.
    def push(model, destroy: false, if: nil)
      raise LockedCollectionError.new("Collection is locked and cannot be changed.", owner) if locked?

      models << wrap(model, destroy:, if:)
      self
    end

    # Returns true if the element exists.
    #
    # @return [Boolean] Returns true if the element exists
    def empty? = models.empty?

    # Set to empty.
    #
    # @return [self] returns itself.
    def clear
      raise LockedCollectionError.new("Collection is locked and cannot be changed.", owner) if locked?

      models.clear
      self
    end

    # Removes the specified model from the collection.
    # Returns nil if the deletion fails, self if it succeeds.
    #
    # @param model [Object] model instance
    # @return [self] Successful deletion
    # @return [nil] If deletion fails
    def delete(model)
      raise LockedCollectionError.new("Collection is locked and cannot be changed.", owner) if locked?

      wrapped = wrap(model)
      return nil unless models.delete(wrapped)

      self
    end

    def locked? = !!@locked

    def lock
      @locked = true
      self
    end

    def unlock
      @locked = false
      self
    end

    def with_lock
      lock
      yield
    ensure
      unlock
    end

    private

    # @private
    attr_reader :owner, :models

    # @private
    def wrap(model, destroy: false, if: nil)
      if destroy.is_a?(Symbol)
        method = destroy
        destroy = -> { owner.__send__(method) }
      end
      if_option = binding.local_variable_get(:if)
      if if_option.is_a?(Symbol)
        method = if_option
        if_option = -> { owner.__send__(method) }
      end
      ActiveRecordCompose::WrappedModel.new(model, destroy:, if: if_option)
    end

    # @private
    module PackagePrivate
      refine ComposedCollection do
        # Returns array of wrapped model instance.
        #
        # @private
        # @return [Array[WrappedModel]] array of wrapped model instance.
        def __wrapped_models = models.reject { _1.ignore? }.select { _1.__raw_model }
      end
    end
  end
end
