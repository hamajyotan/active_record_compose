# frozen_string_literal: true

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

    included do
      # @type self: Class
      class_attribute :delegated_attributes, instance_writer: false
    end

    module ClassMethods
      # Defines the reader and writer for the specified attribute.
      #
      def delegate_attribute(*attributes, to:, allow_nil: nil)
        delegates = attributes.flat_map do |attribute|
          reader = attribute.to_s
          writer = "#{attribute}="

          [reader, writer]
        end

        delegate(*delegates, to:, allow_nil:)
        self.delegated_attributes = delegated_attributes.to_a + attributes.map { _1.to_s }
      end
    end

    # Returns a hash with the attribute name as key and the attribute value as value.
    # Attributes declared with `delegate_attribute` are also merged.
    #
    # @return [Hash] hash with the attribute name as key and the attribute value as value.
    def attributes
      super.merge(delegated_attributes.to_h { [_1, public_send(_1)] })
    end
  end
end
