# frozen_string_literal: true

module ActiveRecordCompose
  module Validations
    def save(**options)
      perform_validations(options) ? super : false
    end

    def save!(**options)
      perform_validations(options) ? super : raise_validation_error
    end

    def valid?(context = nil) = context_for_override_validation.with_override(context) { super }

    private

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
