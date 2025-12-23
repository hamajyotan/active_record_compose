# frozen_string_literal: true

require "test_helper"

class ActiveRecordCompose::ModelWithIfOptionTest < ActiveSupport::TestCase
  class ComposedModelWithOperationLog < ActiveRecordCompose::Model
    def initialize(attributes = {})
      @account = Account.new(name: "foobar", email: "foobar@example.com")
      @operation_log = OperationLog.new(action: "account_registration")
      super(attributes)
      models.push(account)
      models.push(operation_log, if: :output_log)
    end

    attribute :output_log, :boolean, default: true

    private

    attr_reader :account, :operation_log
  end

  test ":if option process is truthy, it is included in the update target." do
    model = ComposedModelWithOperationLog.new(output_log: true)

    assert_difference -> { Account.count } => 1, -> { OperationLog.count } => 1 do
      model.save!
    end
  end

  test ":if option process is falsy, it is not included in the update target." do
    model = ComposedModelWithOperationLog.new(output_log: false)

    assert_difference -> { Account.count } => 1, -> { OperationLog.count } => 0 do
      model.save!
    end
  end
end
