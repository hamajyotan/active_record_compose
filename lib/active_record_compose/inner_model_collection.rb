# frozen_string_literal: true

require 'active_record_compose/inner_model'

module ActiveRecordCompose
  using InnerModel::PackagePrivate

  class InnerModelCollection
    include Enumerable

    def initialize(owner)
      @owner = owner
      @models = []
    end

    # Enumerates model objects.
    #
    # @yieldparam [Object] the model instance
    # @return [Enumerator] when not block given.
    # @return [self] when block given, returns itself.
    def each
      return enum_for(:each) unless block_given?

      models.each { yield _1.__raw_model }
      self
    end

    # Appends model to collection.
    #
    # @param model [Object] the model instance
    # @return [self] returns itself.
    def <<(model)
      models << wrap(model, destroy: false)
      self
    end

    # Appends model to collection.
    #
    # @param model [Object] the model instance
    # @param destroy [Boolean] given true, destroy model.
    # @param destroy [Proc] when proc returning true, destroy model.
    # @param destroy [Symbol] applies boolean value of result of sending a message to `owner` to evaluation.
    # @param if [Proc] evaluation result is false, it will not be included in the renewal.
    # @param if [Symbol] applies boolean value of result of sending a message to `owner` to evaluation.
    # @return [self] returns itself.
    def push(model, destroy: false, if: nil)
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
      models.clear
      self
    end

    # Removes the specified model from the collection.
    # Returns nil if the deletion fails, self if it succeeds.
    #
    # @param model [Object] the model instance
    # @return [self] Successful deletion
    # @return [nil] If deletion fails
    def delete(model)
      wrapped = wrap(model)
      return nil unless models.delete(wrapped)

      self
    end

    private

    attr_reader :owner, :models

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
      ActiveRecordCompose::InnerModel.new(model, destroy:, if: if_option)
    end

    # @private
    module PackagePrivate
      refine InnerModelCollection do
        # Returns array of wrapped model instance.
        #
        # @private
        # @return [Array[InnerModel] array of wrapped model instance.
        def __wrapped_models = models.reject { _1.ignore? }.select { _1.__raw_model }
      end
    end
  end
end
