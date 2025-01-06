# frozen_string_literal: true

require 'test_helper'
require 'active_record_compose/inner_model'

class ActiveRecordCompose::InnerModelTest < ActiveSupport::TestCase
  test 'returns true if and only if model is equivalent' do
    account = Account.new
    profile = Profile.new
    inner_model = ActiveRecordCompose::InnerModel.new(account)

    assert_not_equal inner_model, ActiveRecordCompose::InnerModel.new(profile)
    assert_equal inner_model, ActiveRecordCompose::InnerModel.new(account)
  end

  test 'the states of other elements are not taken into account' do
    account = Account.new
    inner_model = ActiveRecordCompose::InnerModel.new(account)

    assert_equal inner_model, ActiveRecordCompose::InnerModel.new(account, destroy: true)
    assert_equal inner_model, ActiveRecordCompose::InnerModel.new(account, destroy: false)
    assert_equal inner_model, ActiveRecordCompose::InnerModel.new(account, if: -> { false })
  end

  test 'when `destroy` option is false, save model by `#save`' do
    already_persisted_account = Account.create(name: 'foo', email: 'foo@example.com')
    inner_model = ActiveRecordCompose::InnerModel.new(already_persisted_account, destroy: false)

    assert inner_model.save
    assert already_persisted_account.persisted?
  end

  test 'when `destroy` option is true, delete model by `#save`' do
    already_persisted_account = Account.create(name: 'foo', email: 'foo@example.com')
    inner_model = ActiveRecordCompose::InnerModel.new(already_persisted_account, destroy: true)

    assert inner_model.save
    assert already_persisted_account.destroyed?
  end
end
