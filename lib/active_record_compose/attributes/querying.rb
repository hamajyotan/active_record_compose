# frozen_string_literal: true

module ActiveRecordCompose
  module Attributes
    # @private
    # This provides predicate methods based on the attributes.
    #
    # @example
    #   class AccountRegistration < ActiveRecordCompose::Model
    #     def initialize
    #       @account = Account.new
    #       super()
    #       models << account
    #     end
    #
    #     attribute :original_attr
    #     delegate_attribute :name, :email, to: :account
    #
    #     private
    #
    #     attr_reader :account
    #   end
    #
    #   model = AccountRegistration.new
    #
    #   model.name                    #=> nil
    #   model.name?                   #=> false
    #   model.name = "Alice"
    #   model.name?                   #=> true
    #
    #   model.original_attr = "Bob"
    #   model.original_attr?          #=> true
    #   model.original_attr = ""
    #   model.original_attr?          #=> false
    #
    #   # If the value is numeric, it returns the result of checking whether it is zero or not.
    #   # This behavior is consistent with `ActiveRecord::AttributeMethods::Query`.
    #   model.original_attr = 123
    #   model.original_attr?          #=> true
    #   model.original_attr = 0
    #   model.original_attr?          #=> false
    #
    module Querying
      extend ActiveSupport::Concern
      include ActiveModel::AttributeMethods

      included do
        attribute_method_suffix "?", parameters: false
      end

      private

      def attribute?(attr_name) = query?(public_send(attr_name))

      def query?(value)
        case value
        when true then true
        when false, nil then false
        else
          if value.respond_to?(:zero?)
            !value.zero?
          else
            value.present?
          end
        end
      end
    end
  end
end
