# frozen_string_literal: true

require 'active_record_compose/inner_model'

module ActiveRecordCompose
  class InnerModelCollection
    include Enumerable

    # @return [Enumerator] when not block given.
    # @return [InnerModelCollection] self
    def each
      return enum_for(:each) unless block_given?

      models.each { yield _1 }
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
