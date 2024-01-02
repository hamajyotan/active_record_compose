# frozen_string_literal: true

module ActiveRecordCompose
  class InnerModel
    def initialize(inner_model, context: :save)
      @inner_model = inner_model
      @context = context
    end

    delegate :errors, to: :inner_model

    def context
      @context.respond_to?(:call) ? @context.call(inner_model) : @context
    end

    def save!
      case context
      when :destroy
        inner_model.destroy!
      else
        inner_model.save!
      end
    end

    def invalid?
      case context
      when :destroy
        false
      else
        inner_model.invalid?
      end
    end

    def valid? = !invalid?

    private

    attr_reader :inner_model
  end
end
