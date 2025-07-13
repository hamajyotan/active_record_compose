# frozen_string_literal: true

require "test_helper"
require "active_record_compose/attributes"

class ActiveRecordCompose::DelegateAttributeWarningTest < ActiveSupport::TestCase
  class Inner
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :x
    attribute :y
    attribute :z
  end

  setup do
    @deprecator = ActiveRecord.respond_to?(:deprecator) ? ActiveRecord.deprecator : ActiveSupport::Deprecation
  end

  test "Warning if instance variable is directly specified in :to option of delegate_attribute" do
    message = <<~MESSAGE
      Direct use of instance or class variables in `to:` will be removed in the next minor version.
      Please define a reader method (private is fine) and refer to it by name instead.

      For example,
          delegate_attribute :x, :y, to: :@model

      Instead of the above, use the following
          delegate_attribute :x, :y, to: :model
          private
          attr_reader :model

    MESSAGE

    klass = nil
    assert_deprecated(message, @deprecator) do
      klass =
        Class.new(ActiveRecordCompose::Model) do
          def initialize(attributes)
            @model = Inner.new
            super(attributes)
          end

          delegate_attribute :x, :y, to: :@model
        end

      assert { klass.new(x: "foo").x == "foo" }
    end
  end

  test "Warning if class variable is directly specified in :to option of delegate_attribute" do
    message = <<~MESSAGE
      Direct use of instance or class variables in `to:` will be removed in the next minor version.
      Please define a reader method (private is fine) and refer to it by name instead.

      For example,
          delegate_attribute :x, :y, to: :@@model

      Instead of the above, use the following
          delegate_attribute :x, :y, to: :model
          private
          def model = @@model

    MESSAGE

    assert_deprecated(message, @deprecator) do
      klass =
        Class.new(ActiveRecordCompose::Model) do
          class_variable_set(:@@model, Inner.new)
          delegate_attribute :x, :y, to: :@@model
        end

      assert { klass.new(x: "foo").x == "foo" }
    end
  end

  test "If the :allow_nil option is also specified, allow_nil must also be reflected in the suggestion." do
    message = <<~MESSAGE
      Direct use of instance or class variables in `to:` will be removed in the next minor version.
      Please define a reader method (private is fine) and refer to it by name instead.

      For example,
          delegate_attribute :x, :y, to: :@model, allow_nil: true

      Instead of the above, use the following
          delegate_attribute :x, :y, to: :model, allow_nil: true
          private
          attr_reader :model

    MESSAGE

    assert_deprecated(message, @deprecator) do
      klass =
        Class.new(ActiveRecordCompose::Model) do
          def initialize(attributes)
            @model = Inner.new
            super(attributes)
          end

          delegate_attribute :x, :y, to: :@model, allow_nil: true
        end

      assert { klass.new(x: "foo").x == "foo" }
    end
  end
end
