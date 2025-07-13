# frozen_string_literal: true

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
    include ActiveModel::Attributes

    included do
      include Querying

      # @type self: Class
      class_attribute :delegated_attributes, instance_writer: false
    end

    module ClassMethods
      ALLOW_NIL_DEFAULT = Object.new.freeze # steep:ignore
      private_constant :ALLOW_NIL_DEFAULT

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
      def delegate_attribute(*attributes, to:, allow_nil: ALLOW_NIL_DEFAULT) # steep:ignore
        # steep:ignore:start
        if to.start_with?("@")
          suggested_reader_name = to.to_s.sub(/^@+/, "")
          suggested_method =
            if to.start_with?("@@")
              "def #{suggested_reader_name} = #{to}"
            else
              "attr_reader :#{suggested_reader_name}"
            end

          message = <<~MSG
            Direct use of instance or class variables in `to:` will be removed in the next minor version.
            Please define a reader method (private is fine) and refer to it by name instead.

            For example,
                delegate_attribute #{attributes.map { ":#{_1}" }.join(", ")}, to: :#{to}#{", allow_nil: #{allow_nil}" if allow_nil != ALLOW_NIL_DEFAULT}

            Instead of the above, use the following
                delegate_attribute #{attributes.map { ":#{_1}" }.join(", ")}, to: :#{suggested_reader_name}#{", allow_nil: #{allow_nil}" if allow_nil != ALLOW_NIL_DEFAULT}
                private
                #{suggested_method}

          MSG
          (ActiveRecord.respond_to?(:deprecator) ? ActiveRecord.deprecator : ActiveSupport::Deprecation).warn(message)
        end
        allow_nil = false if allow_nil == ALLOW_NIL_DEFAULT
        # steep:ignore:end

        delegations = attributes.map { Delegation.new(attribute: _1, to:, allow_nil:) }
        delegations.each { _1.define_delegated_attribute(self) }

        self.delegated_attributes = (delegated_attributes.to_a + delegations).reverse.uniq { _1.attribute }.reverse
      end

      # Returns a array of attribute name.
      # Attributes declared with `delegate_attribute` are also merged.
      #
      # @return [Array<String>] array of attribute name.
      def attribute_names = super + delegated_attributes.to_a.map { _1.attribute_name }
    end

    # Returns a array of attribute name.
    # Attributes declared with `delegate_attribute` are also merged.
    #
    # @return [Array<String>] array of attribute name.
    def attribute_names = super + delegated_attributes.to_a.map { _1.attribute_name }

    # Returns a hash with the attribute name as key and the attribute value as value.
    # Attributes declared with `delegate_attribute` are also merged.
    #
    # @return [Hash] hash with the attribute name as key and the attribute value as value.
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
    #
    #   registration.attributes # => { "original_attribute" => "qux", "name" => "bar" }
    #
    def attributes
      super.merge(*delegated_attributes.to_a.map { _1.attribute_hash(self) })
    end
  end
end
