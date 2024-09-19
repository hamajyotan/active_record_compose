# frozen_string_literal: true

require 'active_record_compose/inner_model'

module ActiveRecordCompose
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

      models.each { yield _1.__raw_model } # steep:ignore
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
    # @return [self] returns itself.
    def push(model, destroy: false)
      models << wrap(model, destroy:)
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

    # @private
    # Enumerates model objects, but it should be noted that
    # application developers are not expected to use this interface.
    #
    # @yieldparam [InnerModel] rawpped model instance.
    # @return [Enumerator] when not block given.
    # @return [self] when block given, returns itself.
    def __each_by_wrapped
      return enum_for(:__each_by_wrapped) unless block_given?

      models.each { yield _1 if _1.__raw_model } # steep:ignore
      self
    end

    private

    attr_reader :owner, :models

    def wrap(model, destroy: false)
      if model.is_a?(ActiveRecordCompose::InnerModel) # steep:ignore
        # @type var model: ActiveRecordCompose::InnerModel
        model
      else
        if destroy.is_a?(Symbol)
          method = destroy
          destroy = -> { owner.__send__(method) }
        end
        # @type var model: ActiveRecordCompose::_ARLike
        ActiveRecordCompose::InnerModel.new(model, destroy:)
      end
    end
  end
end
