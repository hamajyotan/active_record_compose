# frozen_string_literal: true

require 'active_record_compose/inner_model'

module ActiveRecordCompose
  class InnerModelCollection
    include Enumerable

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
    # @param context [Symbol] :save or :destroy
    # @return [self] returns itself.
    def push(model, destroy: false, context: nil)
      models << wrap(model, destroy:, context:)
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
    # @param destroy [Boolean] given true, destroy model.
    # @param context [Symbol] :save or :destroy
    # @return [self] Successful deletion
    # @return [nil] If deletion fails
    def delete(model, destroy: false, context: nil)
      wrapped = wrap(model, destroy:, context:)
      return nil unless models.delete(wrapped)

      self
    end

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

    def models = @models ||= []

    def wrap(model, destroy:, context: nil)
      if model.is_a?(ActiveRecordCompose::InnerModel) # steep:ignore
        # @type var model: ActiveRecordCompose::InnerModel
        model
      else
        # @type var model: ActiveRecordCompose::_ARLike
        ActiveRecordCompose::InnerModel.new(model, destroy:, context:)
      end
    end
  end
end
