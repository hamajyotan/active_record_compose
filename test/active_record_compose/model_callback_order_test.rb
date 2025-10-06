# frozen_string_literal: true

require "test_helper"
require "active_record_compose/model"

class ActiveRecordCompose::ModelCallbackOrderTest < ActiveSupport::TestCase
  class CallbackOrder < ActiveRecordCompose::Model
    def initialize(tracer, persisted: false)
      @tracer = tracer
      @persisted = persisted
      super()
    end

    before_save { tracer << "before_save called" }
    before_create { tracer << "before_create called" }
    before_update { tracer << "before_update called" }
    after_save { tracer << "after_save called" }
    after_create { tracer << "after_create called" }
    after_update { tracer << "after_update called" }
    after_rollback { tracer << "after_rollback called" }
    after_commit { tracer << "after_commit called" }

    def persisted? = !!@persisted

    private

    attr_reader :tracer
  end

  test "when persisted, #save causes (before|after)_(save|update) and after_commit callback to work" do
    tracer = []
    model = CallbackOrder.new(tracer, persisted: true)

    model.save
    expected =
      [
        "before_save called",
        "before_update called",
        "after_update called",
        "after_save called",
        "after_commit called"
      ]
    assert { tracer == expected }
  end

  test "when not persisted, #save causes (before|after)_(save|create) and after_commit callback to work" do
    tracer = []
    model = CallbackOrder.new(tracer, persisted: false)

    model.save
    expected =
      [
        "before_save called",
        "before_create called",
        "after_create called",
        "after_save called",
        "after_commit called"
      ]
    assert { tracer == expected }
  end

  test "when persisted, #update causes (before|after)_(save|update) and after_commit callback to work" do
    tracer = []
    model = CallbackOrder.new(tracer, persisted: true)

    model.update({})
    expected =
      [
        "before_save called",
        "before_update called",
        "after_update called",
        "after_save called",
        "after_commit called"
      ]
    assert { tracer == expected }
  end

  test "when not persisted, #update causes (before|after)_(save|create) and after_commit callback to work" do
    tracer = []
    model = CallbackOrder.new(tracer, persisted: false)

    model.update({})
    expected =
      [
        "before_save called",
        "before_create called",
        "after_create called",
        "after_save called",
        "after_commit called"
      ]
    assert { tracer == expected }
  end

  test "execution of (before|after)_commit hook is delayed until after the database commit." do
    tracer = []
    model = CallbackOrder.new(tracer)

    ActiveRecord::Base.transaction do
      tracer << "outer transsaction starts"
      ActiveRecord::Base.transaction do
        tracer << "inner transsaction starts"
        model.save
        tracer << "inner transsaction ends"
      end
      tracer << "outer transsaction ends"
    end

    expected =
      [
        "outer transsaction starts",
        "inner transsaction starts",
        "before_save called",
        "before_create called",
        "after_create called",
        "after_save called",
        "inner transsaction ends",
        "outer transsaction ends",
        "after_commit called"
      ]
    assert { tracer == expected }
  end

  test "execution of after_rollback hook is delayed until after the database rollback." do
    tracer = []
    model = CallbackOrder.new(tracer)

    ActiveRecord::Base.transaction do
      tracer << "outer transsaction starts"
      ActiveRecord::Base.transaction do
        tracer << "inner transsaction starts"
        model.save
        tracer << "inner transsaction ends"
      end
      tracer << "outer transsaction ends"
      raise ActiveRecord::Rollback
    end

    expected =
      [
        "outer transsaction starts",
        "inner transsaction starts",
        "before_save called",
        "before_create called",
        "after_create called",
        "after_save called",
        "inner transsaction ends",
        "outer transsaction ends",
        "after_rollback called"
      ]
    assert { tracer == expected }
  end
end
