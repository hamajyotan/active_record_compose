# frozen_string_literal: true

require "test_helper"

class ActiveRecordCompose::MultipleDatabaseTest < ActiveSupport::TestCase
  PRIMARY_DB_MODEL = Account
  SECONDARY_DB_MODEL = SecondaryModel

  class ComposeModel < ActiveRecordCompose::Model
    def initialize(*__models)
      __models.each { models << _1 }
      super()
    end

    attribute :before_commit_calls, :integer, default: 0
    attribute :after_commit_calls, :integer, default: 0
    attribute :after_rollback_calls, :integer, default: 0

    before_commit { self.before_commit_calls += 1 }
    after_commit { self.after_commit_calls += 1 }
    after_rollback { self.after_rollback_calls += 1 }
  end

  test "When the save is successful, all connections will be committed." do
    pri_1 = new_primary_model
    sec_1 = new_secondary_model
    sec_2 = new_secondary_model
    model = ComposeModel.new(pri_1, sec_1, sec_2)

    assert_difference -> { PRIMARY_DB_MODEL.count } => 1 do
      assert_difference -> { SECONDARY_DB_MODEL.count } => 2 do
        model.save!
      end
    end
  end

  test "When the save fails, any connections will be rolled back." do
    pri = new_primary_model.tap { _1.singleton_class.after_save { raise RuntimeError } }
    sec = new_secondary_model
    model = ComposeModel.new(pri, sec)

    assert_no_difference -> { PRIMARY_DB_MODEL.count } do
      assert_no_difference -> { SECONDARY_DB_MODEL.count } do
        model.save!
      rescue RuntimeError # do noghing.
      end
    end

    pri = new_primary_model
    sec = new_secondary_model.tap { _1.singleton_class.after_save { raise RuntimeError } }
    model = ComposeModel.new(pri, sec)

    assert_no_difference -> { PRIMARY_DB_MODEL.count } do
      assert_no_difference -> { SECONDARY_DB_MODEL.count } do
        model.save!
      rescue RuntimeError # do noghing.
      end
    end
  end

  test "When the save is successful, the before_commit and after_commit callbacks will be fired." do
    pri_1 = new_primary_model
    sec_1 = new_secondary_model
    sec_2 = new_secondary_model
    model = ComposeModel.new(pri_1, sec_1, sec_2)

    model.save!

    assert { model.before_commit_calls == 1 }
    assert { model.after_commit_calls == 1 }
    assert { model.after_rollback_calls == 0 }
  end

  test "When the save fails, the after_rollback callback will be fired." do
    pri = new_primary_model.tap { _1.singleton_class.after_save { raise RuntimeError } }
    sec = new_secondary_model
    model = ComposeModel.new(pri, sec)

    begin
      model.save!
    rescue RuntimeError # do noghing.
    end

    assert { model.before_commit_calls == 0 }
    assert { model.after_commit_calls == 0 }
    assert { model.after_rollback_calls == 1 }
  end

  test "dup inside a transaction does not share transaction_coordinator with the original model" do
    klass = Class.new(ActiveRecordCompose::Model) do
      def initialize(inner_model)
        @inner_model = inner_model
        super()
        models << inner_model
      end

      attribute :after_commit_calls, :integer, default: 0
      after_commit { self.after_commit_calls += 1 }

      def replace_model(new_model)
        models.clear
        models << new_model
      end
    end

    pri_model = klass.new(new_primary_model)
    duped_after_commit_calls = nil

    ApplicationRecord.transaction do
      pri_model.save!
      duped = pri_model.dup
      duped.replace_model(new_secondary_model)
      duped.save!
      duped_after_commit_calls = duped.after_commit_calls
    end

    assert { pri_model.after_commit_calls == 1 }
    assert { duped_after_commit_calls == 1 }
  end

  private

  def new_primary_model = PRIMARY_DB_MODEL.new(name: "foo", email: "foo@example.com")

  def new_secondary_model = SECONDARY_DB_MODEL.new
end
