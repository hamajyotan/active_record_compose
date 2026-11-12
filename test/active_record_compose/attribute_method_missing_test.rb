# frozen_string_literal: true

require "test_helper"

# When `attribute_method_suffix` (or `attribute_method_affix`) is called after attributes are declared,
# ActiveModel runs `undefine_attribute_methods` and the generated attribute methods are removed.
# Those methods are then resolved via `method_missing`.
# The resolution must not depend on the values of other (delegated) attributes.
#
class AttributeMethodMissingTest < ActiveSupport::TestCase
  Account = Struct.new(:name)
  Profile = Struct.new(:bio)

  class Model < ActiveRecordCompose::Model
    def initialize(account, profile = nil)
      @account = account
      @profile = profile
      super()
    end

    attribute :foo, :string, default: "x"
    delegate_attribute :name, to: :account
    delegate_attribute :bio, to: :profile

    attribute_method_suffix "_custom", parameters: false

    private

    attr_reader :account, :profile

    def attribute_custom(attr_name) = "custom #{attr_name}"
  end

  test "plain attribute methods work via method_missing" do
    model = Model.new(Account.new("foo"), Profile.new("bar"))

    assert { model.foo == "x" }
    assert { model.foo? == true }
    assert { model.foo_custom == "custom foo" }
    assert { model.name_custom == "custom name" }
  end

  test "plain attribute methods are not affected by delegated attributes whose target is nil" do
    model = Model.new(Account.new("foo"), nil)

    assert { model.foo == "x" }
    assert { model.foo? == true }
    assert { model.foo_custom == "custom foo" }
  end

  test "delegated attribute methods are not affected by other delegated attributes whose target is nil" do
    model = Model.new(Account.new("foo"), nil)

    assert { model.name? == true }
    assert { model.name_custom == "custom name" }
  end

  test "respond_to? is not affected by delegated attributes whose target is nil" do
    model = Model.new(Account.new("foo"), nil)

    assert { model.respond_to?(:foo_custom) }
    assert { model.respond_to?(:name_custom) }
    assert { model.respond_to?(:bio_custom) }
    assert { !model.respond_to?(:unknown_custom) }
  end

  test "attribute methods for undeclared attributes raise NoMethodError" do
    model = Model.new(Account.new("foo"), nil)

    assert_raises(NoMethodError) { model.unknown_custom }
  end

  test "raises UninitializedAttribute if attributes are not initialized" do
    model = Model.allocate

    assert_raises(ActiveRecordCompose::UninitializedAttribute) { model.foo_custom }
    assert_raises(ActiveRecordCompose::UninitializedAttribute) { model.respond_to?(:foo_custom) }
  end
end
