# frozen_string_literal: true

require_relative "attributes/delegatable_attribute"
require_relative "attributes/delegation"
require_relative "attributes/querying"

module ActiveRecordCompose
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
      def delegate_attribute(*attributes, to:, allow_nil: nil)
        delegations = attributes.map { Delegation.new(attribute: _1, to:, allow_nil:) }
        delegations.each { define_attribute_methods(_1.attribute) }

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
