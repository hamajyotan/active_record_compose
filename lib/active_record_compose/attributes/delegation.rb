# frozen_string_literal: true

module ActiveRecordCompose
  module Attributes
    # @private
    class Delegation
      # @return [Symbol] The attribute name as symbol
      attr_reader :attribute

      def initialize(attribute:, to:, allow_nil: false)
        @attribute = attribute.to_sym
        @to = to.to_sym
        @allow_nil = !!allow_nil

        freeze
      end

      def define_delegated_attribute(klass)
        klass.delegate(reader, writer, to:, allow_nil:)
        klass.define_attribute_methods(attribute)
      end

      # @return [String] The attribute name as string
      def attribute_name = attribute.to_s

      def read_attribute(owner)
        target = owner.send(to)
        return nil if target.nil? && allow_nil

        target.public_send(reader)
      end

      def write_attribute(owner, value)
        target = owner.send(to)
        return value if target.nil? && allow_nil

        target.public_send(writer, value)
        value
      end

      private

      attr_reader :to, :allow_nil

      def reader = attribute.to_s

      def writer = "#{attribute}="
    end
  end
end
