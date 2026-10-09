# frozen_string_literal: true

require "test_helper"

class ActiveRecordCompose::MultipleDatabaseCallbackTest < ActiveSupport::TestCase
  class Pri < Account
    attribute :name, :string, default: -> { "foo" }
    attribute :email, :string, default: -> { "foo@example.com" }
    attribute :tracer
    attribute :tag, :string

    before_commit { tracer << "#{tag}: before_commit" }
    after_commit { tracer << "#{tag}: after_commit" }
    after_rollback { tracer << "#{tag}: after_rollback" }
  end

  class Sec < SecondaryModel
    attribute :tracer
    attribute :tag, :string

    before_commit { tracer << "#{tag}: before_commit" }
    after_commit { tracer << "#{tag}: after_commit" }
    after_rollback { tracer << "#{tag}: after_rollback" }
  end

  class ComposeModel < ActiveRecordCompose::Model
    attribute :tracer
    attribute :tag, :string

    def initialize(*__models, tracer:, **attributes)
      __models.each { models << _1 }
      super(tracer:, **attributes)
    end

    before_commit { tracer << "#{tag}: before_commit" }
    after_commit { tracer << "#{tag}: after_commit" }
    after_rollback { tracer << "#{tag}: after_rollback" }
  end

  test "before_commit and after_commit are called upon commit" do
    tracer = []

    pri_1 = Pri.new(tracer:, tag: "---- p1")
    pri_2 = Pri.new(tracer:, tag: "---- p2")
    model = ComposeModel.new(pri_1, pri_2, tracer:, tag: "")

    assert_difference -> { Pri.count } => 2 do
      model.save!
    end
    expected =
      [
        ": before_commit",
        "---- p1: before_commit",
        "---- p2: before_commit",
        ": after_commit",
        "---- p1: after_commit",
        "---- p2: after_commit"
      ]
    assert { tracer == expected }
  end

  test "before_commit fires just before the first commit operation, and after_commit fires just after the last commit operation." do
    tracer = []

    pri_1 = Pri.new(tracer:, tag: "---- p")
    sec_1 = Sec.new(tracer:, tag: "---- s")
    model = ComposeModel.new(pri_1, sec_1, tracer:, tag: "")

    assert_difference -> { Pri.count } => 1 do
      assert_difference -> { Sec.count } => 1 do
        model.save!
      end
    end
    expected =
      [
        "---- p: before_commit",
        "---- p: after_commit",
        ": before_commit",
        "---- s: before_commit",
        ": after_commit",
        "---- s: after_commit"
      ]
    assert { tracer == expected }
  end

  test "If there are multiple database connections, after_commit will only be executed once all connections have terminated." do
    tracer = []

    pri_1 = Pri.new(tracer:, tag: "-------- p")
    inner_1 = ComposeModel.new(pri_1, tracer:, tag: "---- P")

    sec_1 = Sec.new(tracer:, tag: "-------- s")
    inner_2 = ComposeModel.new(sec_1, tracer:, tag: "---- S")

    model = ComposeModel.new(inner_1, inner_2, tracer:, tag: "")

    assert_difference -> { Pri.count } => 1 do
      assert_difference -> { Sec.count } => 1 do
        model.save!
      end
    end
    expected =
      [
        "---- P: before_commit",
        "-------- p: before_commit",
        "---- P: after_commit",
        "-------- p: after_commit",
        ": before_commit",
        "---- S: before_commit",
        "-------- s: before_commit",
        ": after_commit",
        "---- S: after_commit",
        "-------- s: after_commit"
      ]
    assert { tracer == expected }
  end

  test "When executed within an explicit transaction, the callback execution is deferred until the end of the outer transaction." do
    tracer = []

    pri_1 = Pri.new(tracer:, tag: "---- p")
    sec_1 = Sec.new(tracer:, tag: "---- s")

    model = ComposeModel.new(pri_1, sec_1, tracer:, tag: "")

    assert_difference -> { Pri.count } => 1 do
      assert_difference -> { Sec.count } => 1 do
        ApplicationRecord.transaction do
          SecondaryRecord.transaction do
            model.save!
            tracer << "inner transaction"
          end
          tracer << "secondary outer transaction"
        end
        tracer << "primary outer transaction"
      end
    end

    expected =
      [
        "inner transaction",
        "---- s: before_commit",
        "---- s: after_commit",
        "secondary outer transaction",
        ": before_commit",
        "---- p: before_commit",
        ": after_commit",
        "---- p: after_commit",
        "primary outer transaction"
      ]
    assert { tracer == expected }
  end
end
