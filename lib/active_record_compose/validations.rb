# frozen_string_literal: true

require_relative "composed_collection"

module ActiveRecordCompose
  using ComposedCollection::PackagePrivate

  # @private
  module Validations
    extend ActiveSupport::Concern

    included do
      validate :validate_models
    end

    def save(**options)
      perform_validations(options) ? super : false
    end

    def save!(**options)
      perform_validations(options) ? super : raise_validation_error
    end

    def valid?(context = nil) = context_for_override_validation.with_override(context) { super }

    private

    def validate_models
      context = override_validation_context
      models.__wrapped_models.lazy.select { _1.invalid?(context) }.each { errors.merge!(_1) }
    end

    def perform_validations(options)
      options[:validate] == false || valid?(options[:context])
    end

    def raise_validation_error = raise ActiveRecord::RecordInvalid, self

    def context_for_override_validation
      @context_for_override_validation ||= OverrideValidationContext.new
    end

    def override_validation_context = context_for_override_validation.context

    class OverrideValidationContext
      attr_reader :context

      def with_override(context)
        @context, original = context, @context
        yield
      ensure
        @context = original # steep:ignore
      end
    end
    private_constant :OverrideValidationContext
  end
end
