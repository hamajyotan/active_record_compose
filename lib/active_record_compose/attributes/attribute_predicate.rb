# frozen_string_literal: true

module ActiveRecordCompose
  module Attributes
    # @private
    class AttributePredicate
      def initialize(value)
        @value = value
      end

      def call
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

      private

      attr_reader :value
    end
  end
end
