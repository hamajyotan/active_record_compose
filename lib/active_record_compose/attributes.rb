# frozen_string_literal: true

require_relative "attributes/attribute_predicate"
require_relative "attributes/delegation"
require_relative "attributes/querying"
require_relative "exceptions"

module ActiveRecordCompose
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
      # @type self: Class

      include Querying

      class_attribute :delegated_attributes, instance_writer: false
    end

    # steep:ignore:start

    class_methods do
      # Provides a method of attribute access to the encapsulated model.
      #
      # It provides a way to access the attributes of the model it encompasses,
      # allowing transparent access as if it had those attributes itself.
      #
      # @param [Array<Symbol, String>] attributes
      #   attributes A variable-length list of attribute names to delegate.
      # @param [Symbol, String] to
      #   The target object to which attributes are delegated (keyword argument).
      # @param [Boolean] allow_nil
      #   allow_nil Whether to allow nil values. Defaults to false.
      # @example Basic usage
      #   delegate_attribute :name, :email, to: :profile
      # @example Allowing nil
      #   delegate_attribute :bio, to: :profile, allow_nil: true
      # @see Module#delegate for similar behavior in ActiveSupport
      def delegate_attribute(*attributes, to:, allow_nil: false)
        if to.start_with?("@")
          raise ArgumentError, "Instance variables cannot be specified in delegate to. (#{to})"
        end

        delegations = attributes.map { Delegation.new(attribute: _1, to:, allow_nil:) }
        delegations.each { _1.define_delegated_attribute(self) }

        self.delegated_attributes = (delegated_attributes.to_a + delegations).reverse.uniq { _1.attribute }.reverse
      end

      # Returns a array of attribute name.
      # Attributes declared with {.delegate_attribute} are also merged.
      #
      # @see #attribute_names
      # @return [Array<String>] array of attribute name.
      def attribute_names = super + delegated_attributes.to_a.map { _1.attribute_name }
    end

    # steep:ignore:end

    # Returns a array of attribute name.
    # Attributes declared with {.delegate_attribute} are also merged.
    #
    #     class Foo < ActiveRecordCompose::Base
    #       def initialize(attributes = {})
    #         @account = Account.new
    #         super
    #       end
    #
    #       attribute :confirmation, :boolean, default: false   # plain attribute
    #       delegate_attribute :name, to: :account              # delegated attribute
    #
    #       private
    #
    #       attr_reader :account
    #     end
    #
    #     Foo.attribute_names                                   # Returns the merged state of plain and delegated attributes
    #     # => ["confirmation" ,"name"]
    #
    #     foo = Foo.new
    #     foo.attribute_names                                   # Similar behavior for instance method version
    #     # => ["confirmation", "name"]
    #
    # @see #attributes
    # @return [Array<String>] array of attribute name.
    def attribute_names
      _require_attributes_initialized do
        super + delegated_attributes.to_a.map { _1.attribute_name }
      end
    end

    # Returns a hash with the attribute name as key and the attribute value as value.
    # Attributes declared with {.delegate_attribute} are also merged.
    #
    #     class Foo < ActiveRecordCompose::Base
    #       def initialize(attributes = {})
    #         @account = Account.new
    #         super
    #       end
    #
    #       attribute :confirmation, :boolean, default: false   # plain attribute
    #       delegate_attribute :name, to: :account              # delegated attribute
    #
    #       private
    #
    #       attr_reader :account
    #     end
    #
    #     foo = Foo.new
    #     foo.name = "Alice"
    #     foo.confirmation = true
    #
    #     foo.attributes                                        # Returns the merged state of plain and delegated attributes
    #     # => { "confirmation" => true, "name" => "Alice" }
    #
    # @return [Hash<String, Object>] hash with the attribute name as key and the attribute value as value.
    def attributes
      _require_attributes_initialized do
        super.merge(*delegated_attributes.to_a.map { _1.attribute_hash(self) })
      end
    end

    private

    def _write_attribute(...) = _require_attributes_initialized { super } # steep:ignore

    def attribute(...) = _require_attributes_initialized { super }

    def _require_attributes_initialized
      unless @attributes
        raise ActiveRecordCompose::UninitializedAttribute,
              "No attributes have been set. Is proper initialization performed, such as calling `super` in `initialize`?"
      end

      yield
    end
  end
end
