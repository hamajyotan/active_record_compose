# frozen_string_literal: true

require_relative "attributes/delegation"
require_relative "attributes/querying"

module ActiveRecordCompose
  module Attributes
    extend ActiveSupport::Concern
    include ActiveModel::Attributes

    included do
      include Querying

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
