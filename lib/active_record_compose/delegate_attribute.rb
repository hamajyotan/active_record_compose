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
      class_attribute :delegated_attributes, instance_writer: false # steep:ignore
    end

    module ClassMethods
      # Defines the reader and writer for the specified attribute.
      #
      def delegate_attribute(*attributes, to:, allow_nil: nil, private: nil)
        delegates = attributes.flat_map do |attribute|
          reader = attribute.to_s
          writer = "#{attribute}="

          [reader, writer]
        end

        delegate(*delegates, to:, allow_nil:, private:) # steep:ignore
        delegated_attributes = (self.delegated_attributes ||= []) # steep:ignore
        attributes.each { delegated_attributes.push(_1.to_s) }
      end
    end

    # Returns a hash with the attribute name as key and the attribute value as value.
    # Attributes declared with `delegate_attribute` are also merged.
    #
    # @return [Hash] hash with the attribute name as key and the attribute value as value.
    def attributes
      attrs = defined?(super) ? super : {} # steep:ignore
      delegates = delegated_attributes # steep:ignore

      # @type var attrs: Hash[String, untyped]
      # @type var delegates: Array[String]
      attrs.merge(delegates.to_h { [_1, public_send(_1)] })
    end
  end
end
