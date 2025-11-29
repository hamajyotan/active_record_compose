# frozen_string_literal: true

require_relative "composed_collection"

module ActiveRecordCompose
  using ComposedCollection::PackagePrivate

  module Validations
    extend ActiveSupport::Concern
    include ActiveModel::Validations::Callbacks

    included do
      validate :validate_models
    end

    def save(**options)
      perform_validations(options) ? super : false
    end

    def save!(**options)
      perform_validations(options) ? super : raise_validation_error
    end

    # Runs all the validations and returns the result as true or false.
    #
    # @param context Validation context.
    # @return [Boolean] true on success, false on failure.
    def valid?(context = nil) = context_for_override_validation.with_override(context) { super }

    # @!method validate(context = nil)
    #   Alias for {#valid?}
    #   @see #valid? Validation context.
    #   @param context
    #   @return [Boolean] true on success, false on failure.

    # @!method validate!(context = nil)
    #   @see #valid?
    #   Runs all the validations within the specified context.
    #   no errors are found, raises `ActiveRecord::RecordInvalid` otherwise.
    #   @param context Validation context.
    #   @raise ActiveRecord::RecordInvalid

    # @!method errors
    #   Returns the `ActiveModel::Errors` object that holds all information about attribute error messages.
    #
    #   The `ActiveModel::Base` implementation itself,
    #   but also aggregates error information for objects stored in {#models} when validation is performed.
    #
    #       class Account < ActiveRecord::Base
    #         validates :name, :email, presence: true
    #       end
    #
    #       class AccountRegistration < ActiveRecordCompose::Model
    #         def initialize(attributes = {})
    #           @account = Account.new
    #           super(attributes)
    #           models << account
    #         end
    #
    #         attribute :confirmation, :boolean, default: false
    #         validates :confirmation, presence: true
    #
    #         private
    #
    #         attr_reader :account
    #       end
    #
    #       registration = AccountRegistration
    #       registration.valid?
    #       #=> false
    #
    #       # In addition to the model's own validation error information (`confirmation`), also aggregates
    #       # error information for objects stored in `account` (`name`, `email`) when validation is performed.
    #
    #       registration.errors.map { _1.attribute }  #=> [:name, :email, :confirmation]
    #
    #   @return [ActiveModel::Errors]

    private

    # @private
    def validate_models
      context = override_validation_context
      models.__wrapped_models.lazy.select { _1.invalid?(context) }.each { errors.merge!(_1) }
    end

    # @private
    def perform_validations(options)
      options[:validate] == false || valid?(options[:context])
    end

    # @private
    def raise_validation_error = raise ActiveRecord::RecordInvalid, self

    # @private
    def context_for_override_validation
      @context_for_override_validation ||= OverrideValidationContext.new
    end

    # @private
    def override_validation_context = context_for_override_validation.context

    # @private
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
