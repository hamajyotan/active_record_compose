# frozen_string_literal: true

require 'test_helper'
require 'active_record_compose/model'

class ActiveRecordCompose::ModelNestedTest < ActiveSupport::TestCase
  class InnerComposedModel < ActiveRecordCompose::Model
    def initialize
      @account = Account.new
      super()
      models << account
    end

    validates :name, length: { maximum: 10 }

    delegate_attribute :name, :email, to: :account

    private

    attr_reader :account
  end

  class OuterComposedModel < ActiveRecordCompose::Model
    def initialize
      @inner_model = InnerComposedModel.new
      super()
      models << inner_model
    end

    delegate_attribute :name, :email, to: :inner_model

    private

    attr_reader :inner_model
  end

  test 'Ensure a ComposedModel can be saved correctly even when it contains another ComposedModel' do
    model = OuterComposedModel.new
    model.assign_attributes(name: 'foo', email: 'foo@example.com')

    assert_difference -> { Account.count } => 1 do
      model.save!
    end
  end

  test 'Ensure errors propagate correctly even when a ComposedModel contains another ComposedModel and is invalid.' do
    model = OuterComposedModel.new
    model.assign_attributes(name: 'veryverylongname')

    assert model.invalid?
    assert { model.errors.to_a == ["Email can't be blank", 'Name is too long (maximum is 10 characters)'] }
  end
end
