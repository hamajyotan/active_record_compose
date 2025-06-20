# frozen_string_literal: true

require "test_helper"
require "active_record_compose/wrapped_model"

class ActiveRecordCompose::WrappedModelTest < ActiveSupport::TestCase
  test "returns true if and only if model is equivalent" do
    account = Account.new
    profile = Profile.new
    wrapped_model = ActiveRecordCompose::WrappedModel.new(account)

    assert { wrapped_model != ActiveRecordCompose::WrappedModel.new(profile) }
    assert { wrapped_model == ActiveRecordCompose::WrappedModel.new(account) }
  end

  test "the states of other elements are not taken into account" do
    account = Account.new
    wrapped_model = ActiveRecordCompose::WrappedModel.new(account)

    assert { wrapped_model == ActiveRecordCompose::WrappedModel.new(account, destroy: true) }
    assert { wrapped_model == ActiveRecordCompose::WrappedModel.new(account, destroy: false) }
    assert { wrapped_model == ActiveRecordCompose::WrappedModel.new(account, if: -> { false }) }
  end

  test "when `destroy` option is false, save model by `#save`" do
    already_persisted_account = Account.create(name: "foo", email: "foo@example.com")
    wrapped_model = ActiveRecordCompose::WrappedModel.new(already_persisted_account, destroy: false)

    assert wrapped_model.save
    assert already_persisted_account.persisted?
  end

  test "when `destroy` option is true, delete model by `#save`" do
    already_persisted_account = Account.create(name: "foo", email: "foo@example.com")
    wrapped_model = ActiveRecordCompose::WrappedModel.new(already_persisted_account, destroy: true)

    assert wrapped_model.save
    assert already_persisted_account.destroyed?
  end
end
