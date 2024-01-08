# frozen_string_literal: true

require 'active_record_compose/inner_model'

module ActiveRecordCompose
  class InnerModelCollection
    include Enumerable

    # Enumerates model objects.
    #
    # @yieldparam [Object] the model instance
    # @return [Enumerator] when not block given.
    # @return [InnerModelCollection] self
    def each
      return enum_for(:each) unless block_given?

      models.each { yield _1.__raw_model }
      self
    end

    # Appends model to collection.
    #
    # @param model [Object] the model instance
    # @param context [Symbol] :save or :destroy
    # @return [InnerModelCollection] self
    def <<(model)
      models << wrap(model, context: :save)
      self
    end

    # Appends model to collection.
    #
    # @param model [Object] the model instance
    # @return [InnerModelCollection] self
    def push(model, context: :save)
      models << wrap(model, context:)
      self
    end

    # Enumerates model objects, but it should be noted that
    # application developers are not expected to use this interface.
    #
    # @yieldparam [InnerModel] rawpped model instance.
    # @return [Enumerator] when not block given.
    # @return [InnerModelCollection] self
    def __each_by_wrapped
      return enum_for(:__each_by_wrapped) unless block_given?

      models.each { yield _1 }
      self
    end

    private

    def models = @models ||= []

    def wrap(model, context:)
      if model.is_a?(ActiveRecordCompose::InnerModel)
        model
      else
        ActiveRecordCompose::InnerModel.new(model, context:)
      end
    end
  end
end
