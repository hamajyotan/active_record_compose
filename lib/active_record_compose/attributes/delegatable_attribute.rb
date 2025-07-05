# frozen_string_literal: true

require "active_support/core_ext/module"

module ActiveRecordCompose
  module Attributes
    # ActiveModel::Attribute is an element encapsulated in ActiveModel::AttributeSet.
    # Attributes defined by `delegate_attribute` will also have an interface compatible with this to
    # `#attributes` and other operations.
    #
    # @private
    class DelegatableAttribute
      def initialize(delegation, owner)
        @delegation = delegation
        @owner = owner
        @type = ActiveModel::Type.default_value
      end

      def value(&) = _read

      def with_value_from_user(value) = _write(value)

      def initialized? = true

      def dup_or_share = self

      def with_type(type) = self

      def type_cast(value) = type.cast(value)

      # steep:ignore:start

      # Operations required by ActiveModel::Dirty
      # Not supported at this time, so only the minimum response is implemented.
      #
      concerning :ForDirty do
        def original_value = value

        def changed? = false

        def changed_in_place? = false

        def forgetting_assignment = self
      end

      # Operations required by ActiveRecord
      # Not supported at this time, so only the minimum response is implemented.
      #
      concerning :ForActiveRecord do
        def came_from_user? = false

        def serializable? = false

        def has_been_read? = true

        def value_for_database = value

        def with_value_from_database(value) = with_value_from_user(value)

        def original_value_for_database = original_value

        def with_cast_value(value) = with_value_from_database(value)
      end

      # steep:ignore:end

      private

      attr_reader :delegation, :owner, :type

      def _read = delegation.read_attribute(owner)

      def _write(value)
        delegation.write_attribute(owner, value)
        self
      end
    end
  end
end
