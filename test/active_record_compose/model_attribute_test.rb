# frozen_string_literal: true

require "test_helper"

class ActiveRecordCompose::ModelAttributeTest < ActiveSupport::TestCase
  test "If you don't call super in initialize, the attributes won't be accessible because they won't be initialized." do
    klass =
      Class.new(ActiveRecordCompose::Model) do
        def initialize
          @account = Account.new(name: "Alice", email: "alice@example.com")
          models << account
        end

        attribute :confirmation, :boolean, default: false
        validates :confirmation, presence: true

        private

        attr_reader :account
      end
    model = klass.new

    e =
      assert_raises(ActiveRecordCompose::UninitializedAttribute) do
        model.confirmation = true
      end
    assert { e.message == "No attributes have been set. Is proper initialization performed, such as calling `super` in `initialize`?" }
  end

  test "Inspect works even if attributes are not initialized" do
    klass =
      Class.new(ActiveRecordCompose::Model) do
        def self.to_s = "Klass"

        def initialize
        end

        attribute :confirmation, :boolean, default: false
      end
    model = klass.new

    assert { model.inspect == "#<Klass not initialized>" }
  end

  test "If you call super during initialization, the attribute will be initialized and you will be able to access it." do
    klass =
      Class.new(ActiveRecordCompose::Model) do
        def initialize
          @account = Account.new(name: "Alice", email: "alice@example.com")
          models << account
          super()
        end

        attribute :confirmation, :boolean, default: false
        validates :confirmation, presence: true

        private

        attr_reader :account
      end
    model = klass.new

    assert_difference -> { Account.count } => 1 do
      model.confirmation = true
      model.save!
    end
  end
end
