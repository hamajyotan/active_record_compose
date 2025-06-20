# frozen_string_literal: true

require "test_helper"
require "active_record_compose/model"

class ActiveRecordCompose::ModelCallbackAbortTest < ActiveSupport::TestCase
  class CallbackWithAbort < ActiveRecordCompose::Model
    def initialize(account = Account.new)
      @account = account
      super()
      models << account
    end

    attribute :throw_flag, :boolean, default: false
    attribute :after_save_called, :boolean, default: false

    delegate_attribute :name, :email, to: :account

    before_save do
      throw(:abort) if throw_flag
    end

    after_save { self.after_save_called = true }

    private

    attr_reader :account
  end

  test "when :abort is not thrown in the before hook, it should be saved normally" do
    model = CallbackWithAbort.new
    model.assign_attributes(name: "foo", email: "foo@example.com", throw_flag: false)

    assert_difference -> { Account.count } => 1 do
      assert model.save
    end
    assert model.after_save_called
  end

  test "when :abort is thrown in the before hook, the save must fail" do
    model = CallbackWithAbort.new
    model.assign_attributes(name: "foo", email: "foo@example.com", throw_flag: true)

    assert_no_changes -> { Account.count } do
      assert_not model.save
    end
    assert_not model.after_save_called
  end
end
