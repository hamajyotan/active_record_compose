# frozen_string_literal: true

require 'active_support/core_ext/object'

module ActiveRecordCompose
  class InnerModel
    # @param model [Object] the model instance.
    # @param context [Symbol] :save or :destroy
    def initialize(model, context: :save)
      @model = model
      @context = context
    end

    delegate :errors, to: :model

    # @return [Symbol] :save or :destroy
    def context
      ret = @context.respond_to?(:call) ? @context.call(model) : @context
      ret.presence_in(%i[save destroy]) || :save
    end

    # @return [InnerModel] self
    def save!
      case context
      when :destroy
        model.destroy!
      else
        model.save!
      end
    end

    # @return [Boolean]
    def invalid?
      case context
      when :destroy
        false
      else
        model.invalid?
      end
    end

    # @return [Boolean]
    def valid? = !invalid?

    # Returns a model instance of raw, but it should
    # be noted that application developers are not expected to use this interface.
    #
    # @return [Object] raw model instance
    def __raw_model = model

    private

    attr_reader :model
  end
end
