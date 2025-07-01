# frozen_string_literal: true

module ActiveRecordCompose
  module DelegateAttribute
    class Delegation
      attr_reader :attribute

      def initialize(attribute:, to:, allow_nil: nil)
        @attribute = attribute.to_sym
        @to = to.to_sym
        @allow_nil = !!allow_nil

        freeze
      end

      def define_delegated_attribute(klass)
        klass.delegate(reader, writer, to:, allow_nil:)
        klass.define_attribute_methods(attribute)
      end

      def attribute_name = attribute.to_s

      def attribute_hash(model)
        { attribute_name => model.public_send(attribute) }
      end

      private

      attr_reader :to, :allow_nil

      def reader = attribute.to_s

      def writer = "#{attribute}="
    end
  end
end
