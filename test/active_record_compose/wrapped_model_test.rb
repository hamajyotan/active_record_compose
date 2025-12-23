# frozen_string_literal: true

require "test_helper"

class ActiveRecordCompose::WrappedModelTest < ActiveSupport::TestCase
  test "returns true if and only if model is equivalent" do
    account = Account.new
    profile = Profile.new
    wrapped_model = ActiveRecordCompose::WrappedModel.new(account)

    assert { wrapped_model != described_class.new(profile) }
    assert { wrapped_model == described_class.new(account) }
  end

  test "the :destroy option is also taken into account to determine equivalence" do
    account = Account.new

    assert { described_class.new(account) == described_class.new(account, destroy: false) }
    assert { described_class.new(account) != described_class.new(account, destroy: true) }

    destroy_proc = -> { true }
    other_destroy_proc = -> { true }
    assert { described_class.new(account, destroy: destroy_proc) == described_class.new(account, destroy: destroy_proc) }
    assert { described_class.new(account, destroy: destroy_proc) != described_class.new(account, destroy: other_destroy_proc) }
  end

  test "the :if option is also taken into account to determine equivalence" do
    account = Account.new

    if_proc = -> { true }
    other_if_proc = -> { true }
    assert { described_class.new(account, if: if_proc) == described_class.new(account, if: if_proc) }
    assert { described_class.new(account, if: if_proc) != described_class.new(account, if: other_if_proc) }
  end

  test "when `destroy` option is false, save model by `#save`" do
    already_persisted_account = Account.create(name: "foo", email: "foo@example.com")
    wrapped_model = described_class.new(already_persisted_account, destroy: false)

    assert { wrapped_model.save }
    assert { already_persisted_account.persisted? }
  end

  test "when `destroy` option is true, delete model by `#save`" do
    already_persisted_account = Account.create(name: "foo", email: "foo@example.com")
    wrapped_model = described_class.new(already_persisted_account, destroy: true)

    assert { wrapped_model.save }
    assert { already_persisted_account.destroyed? }
  end

  private

  def described_class = ActiveRecordCompose::WrappedModel
end
