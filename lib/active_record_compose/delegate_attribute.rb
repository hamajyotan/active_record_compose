# frozen_string_literal: true

require_relative "delegate_attribute/delegation"

module ActiveRecordCompose
  # = Delegate \Attribute
  #
  # It provides a macro description that expresses access to the attributes of the AR model through delegation.
  #
  #   class AccountRegistration < ActiveRecordCompose::Model
  #     def initialize(account, attributes = {})
  #       @account = account
  #       super(attributes)
  #       models.push(account)
  #     end
  #
  #     attribute :original_attribute, :string, default: 'qux'
  #
  #     # like a `delegate :name, :name=, to: :account`
  #     delegate_attribute :name, to: :account
  #
  #     private
  #
  #     attr_reader :account
  #   end
  #
  #   account = Account.new
  #   account.name = 'foo'
  #
  #   registration = AccountRegistration.new(account)
  #   registration.name  #=> 'foo'  # delegate to account#name
  #
  #   registration.name = 'bar'  # delegate to account#name=
  #   account.name  #=> 'bar'
  #
  #   # Attributes defined in delegate_attribute will be included in the original `#attributes`.
  #   registration.attributes  #=> { 'original_attribute' => 'qux', 'name' => 'bar' }
  #
  module DelegateAttribute
    extend ActiveSupport::Concern
    include ActiveModel::Attributes

    included do
      # @type self: Class
      class_attribute :delegated_attributes, instance_writer: false
    end

    module ClassMethods
      # Defines the reader and writer for the specified attribute.
      #
      def delegate_attribute(*attributes, to:, allow_nil: nil)
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
    def attributes
      super.merge(*delegated_attributes.to_a.map { _1.attribute_hash(self) })
    end
  end
end
