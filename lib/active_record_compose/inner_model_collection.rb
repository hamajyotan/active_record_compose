# frozen_string_literal: true

require 'active_record_compose/inner_model'

module ActiveRecordCompose
  class InnerModelCollection
    include Enumerable

    def initialize
      @inner_models = []
    end

    def each
      return enum_for(:each) unless block_given?

      inner_models.each { yield _1 }
      self
    end

    def <<(inner_model)
      inner_models << wrap(inner_model, context: :save)
      self
    end

    def push(inner_model, context: :save)
      inner_models << wrap(inner_model, context:)
      self
    end

    private

    attr_reader :inner_models

    def wrap(inner_model, context:)
      if inner_model.is_a?(ActiveRecordCompose::InnerModel)
        inner_model
      else
        ActiveRecordCompose::InnerModel.new(inner_model, context:)
      end
    end
  end
end
