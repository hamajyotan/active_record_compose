# frozen_string_literal: true

require "test_helper"

class ActiveRecordCompose::MultipleDatabaseCallbackTest < ActiveSupport::TestCase
  class Pri < Account
    attribute :name, :string, default: -> { "foo" }
    attribute :email, :string, default: -> { "foo@example.com" }
    attribute :tracer
    attribute :tag, :string

    before_commit { tracer << "#{tag}: before_commit called!" }
    after_commit { tracer << "#{tag}: after_commit called!" }
    after_rollback { tracer << "#{tag}: after_rollback called!" }
  end

  class Sec < SecondaryModel
    attribute :tracer
    attribute :tag, :string

    before_commit { tracer << "#{tag}: before_commit called!" }
    after_commit { tracer << "#{tag}: after_commit called!" }
    after_rollback { tracer << "#{tag}: after_rollback called!" }
  end

  class ComposeModel < ActiveRecordCompose::Model
    attribute :tracer
    attribute :tag, :string

    def initialize(*__models, tracer:, **attributes)
      __models.each { models << _1 }
      super(tracer:, **attributes)
    end

    before_commit { tracer << "#{tag}: before_commit called!" }
    after_commit { tracer << "#{tag}: after_commit called!" }
    after_rollback { tracer << "#{tag}: after_rollback called!" }
  end

  test "before_commit and after_commit are called upon commit" do
    tracer = []

    pri_1 = Pri.new(tracer:, tag: "p_1")
    pri_2 = Pri.new(tracer:, tag: "p_2")
    model = ComposeModel.new(pri_1, pri_2, tracer:, tag: "__1")

    assert_difference -> { Pri.count } => 2 do
      model.save!
    end
    expected =
      [
        "__1: before_commit called!",
        "p_1: before_commit called!",
        "p_2: before_commit called!",
        "__1: after_commit called!",
        "p_1: after_commit called!",
        "p_2: after_commit called!"
      ]
    assert { tracer == expected }
  end

  test "before_commit fires just before the first commit operation, and after_commit fires just after the last commit operation." do
    tracer = []

    pri_1 = Pri.new(tracer:, tag: "p_1")
    sec_1 = Sec.new(tracer:, tag: "s_1")
    model = ComposeModel.new(pri_1, sec_1, tracer:, tag: "__1")

    assert_difference -> { Pri.count } => 1 do
      assert_difference -> { Sec.count } => 1 do
        model.save!
      end
    end
    expected =
      [
        "p_1: before_commit called!",
        "p_1: after_commit called!",
        "__1: before_commit called!",
        "s_1: before_commit called!",
        "__1: after_commit called!",
        "s_1: after_commit called!"
      ]
    assert { tracer == expected }
  end

  test "If there are multiple database connections, after_commit will only be executed once all connections have terminated." do
    tracer = []

    pri_1 = Pri.new(tracer:, tag: "p_1")
    inner_1 = ComposeModel.new(pri_1, tracer:, tag: "__1")

    sec_1 = Sec.new(tracer:, tag: "s_1")
    inner_2 = ComposeModel.new(sec_1, tracer:, tag: "__2")

    model = ComposeModel.new(inner_1, inner_2, tracer:, tag: "__3")

    assert_difference -> { Pri.count } => 1 do
      assert_difference -> { Sec.count } => 1 do
        model.save!
      end
    end
    expected =
      [
        "__1: before_commit called!",
        "p_1: before_commit called!",
        "__1: after_commit called!",
        "p_1: after_commit called!",
        "__3: before_commit called!",
        "__2: before_commit called!",
        "s_1: before_commit called!",
        "__3: after_commit called!",
        "__2: after_commit called!",
        "s_1: after_commit called!"
      ]
    assert { tracer == expected }
  end

  test "When executed within an explicit transaction, the callback execution is deferred until the end of the outer transaction." do
    tracer = []

    pri_1 = Pri.new(tracer:, tag: "p_1")
    sec_1 = Sec.new(tracer:, tag: "s_1")

    model = ComposeModel.new(pri_1, sec_1, tracer:, tag: "__1")

    assert_difference -> { Pri.count } => 1 do
      assert_difference -> { Sec.count } => 1 do
        ApplicationRecord.transaction do
          SecondaryRecord.transaction do
            model.save!
            tracer << "---: inner transaction"
          end
          tracer << "---: secondary outer transaction"
        end
        tracer << "---: primary outer transaction"
      end
    end

    expected =
      [
        "---: inner transaction",
        "s_1: before_commit called!",
        "s_1: after_commit called!",
        "---: secondary outer transaction",
        "__1: before_commit called!",
        "p_1: before_commit called!",
        "__1: after_commit called!",
        "p_1: after_commit called!",
        "---: primary outer transaction"
      ]
    assert { tracer == expected }
  end
end
