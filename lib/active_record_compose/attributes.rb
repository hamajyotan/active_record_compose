# frozen_string_literal: true

require_relative "attributes/delegatable_attribute"
require_relative "attributes/delegation"
require_relative "attributes/querying"

module ActiveRecordCompose
  # @private
  #
  # Provides attribute-related functionality for use within ActiveRecordCompose::Model.
  #
  # This module allows you to define attributes on your composed model, including support
  # for query methods (e.g., `#attribute?`) and delegation of attributes to underlying
  # ActiveRecord instances via macros.
  #
  # For example, `.delegate_attribute` defines attribute accessors that delegate to
  # a specific model, similar to:
  #
  #     delegate :name, :name=, to: :account
  #
  # Additionally, delegated attributes are included in the composed model's `#attributes`
  # hash.
  #
  # @example
  #   class AccountRegistration < ActiveRecordCompose::Model
  #     def initialize(account, attributes = {})
  #       @account = account
  #       super(attributes)
  #       models.push(account)
  #     end
  #
  #     attribute :original_attribute, :string, default: "qux"
  #     delegate_attribute :name, to: :account
  #
  #     private
  #
  #     attr_reader :account
  #   end
  #
  #   account = Account.new
  #   account.name = "foo"
  #
  #   registration = AccountRegistration.new(account)
  #   registration.name         # => "foo" (delegated)
  #   registration.name?        # => true  (delegated attribute method + `?`)
  #
  #   registration.name = "bar" # => updates account.name
  #   account.name              # => "bar"
  #   account.name?             # => true
  #
  #   registration.attributes
  #   # => { "original_attribute" => "qux", "name" => "bar" }
  #
  module Attributes
    extend ActiveSupport::Concern

    included do
      include ActiveModel::Attributes
      include Querying

      # @type self: Class
      class_attribute :delegated_attributes, instance_writer: false

      # steep:ignore:start

      # Returns a array of attribute name.
      # Attributes declared with `delegate_attribute` are also merged.
      #
      # @return [Array<String>] array of attribute name.
      def self.attribute_names = super + delegated_attributes.to_a.map { _1.attribute_name }

      # steep:ignore:end
    end

    module ClassMethods
      # Defines the reader and writer for the specified attribute.
      #
      # @example
      #   class AccountRegistration < ActiveRecordCompose::Model
      #     def initialize(account, attributes = {})
      #       @account = account
      #       super(attributes)
      #       models.push(account)
      #     end
      #
      #     attribute :original_attribute, :string, default: "qux"
      #     delegate_attribute :name, to: :account
      #
      #     private
      #
      #     attr_reader :account
      #   end
      #
      #   account = Account.new
      #   account.name = "foo"
      #
      #   registration = AccountRegistration.new(account)
      #   registration.name         # => "foo" (delegated)
      #   registration.name?        # => true  (delegated attribute method + `?`)
      #
      #   registration.name = "bar" # => updates account.name
      #   account.name              # => "bar"
      #   account.name?             # => true
      #
      #   registration.attributes
      #   # => { "original_attribute" => "qux", "name" => "bar" }
      #
      def delegate_attribute(*attributes, to:, allow_nil: false)
        if to.start_with?("@")
          raise ArgumentError, "Instance variables cannot be specified in delegate to. (#{to})"
        end

        delegations = attributes.map { Delegation.new(attribute: _1, to:, allow_nil:) }
        delegations.each { _1.define_delegated_attribute(self) }

        self.delegated_attributes = (delegated_attributes.to_a + delegations).reverse.uniq { _1.attribute }.reverse
      end
    end

    # steep:ignore:start
    private_module = Module.new do
      refine Attributes do
        private

        def _merge_delegated_attributes
          delegated_attributes.to_a.each do |delegation|
            @attributes[delegation.attribute_name] = DelegatableAttribute.new(delegation, self)
          end
        end
      end
    end
    using private_module
    # steep:ignore:end

    # steep:ignore:start
    def initialize(...)
      _merge_delegated_attributes
      super
    end
    # steep:ignore:end
  end
end
