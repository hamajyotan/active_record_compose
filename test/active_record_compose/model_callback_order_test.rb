# frozen_string_literal: true

require "test_helper"

class ActiveRecordCompose::ModelCallbackOrderTest < ActiveSupport::TestCase
  class CallbackOrder < ActiveRecordCompose::Model
    def initialize(tracer, persisted: false, inner: nil)
      @tracer = tracer
      @persisted = persisted
      super()
      Array.wrap(inner).each { models << _1 }
    end

    before_validation { tracer << "before_validation" }
    before_save { tracer << "before_save" }
    before_create { tracer << "before_create" }
    before_update { tracer << "before_update" }
    before_commit { tracer << "before_commit" }
    after_validation { tracer << "after_validation" }
    after_save { tracer << "after_save" }
    after_create { tracer << "after_create" }
    after_update { tracer << "after_update" }
    after_rollback { tracer << "after_rollback" }
    after_commit { tracer << "after_commit" }

    def persisted? = !!@persisted

    private

    attr_reader :tracer
  end

  class Inner < Account
    attribute :tracer

    before_validation { tracer << "--- before_validation" }
    before_save { tracer << "--- before_save" }
    before_create { tracer << "--- before_create" }
    before_update { tracer << "--- before_update" }
    before_commit { tracer << "--- before_commit" }
    after_validation { tracer << "--- after_validation" }
    after_save { tracer << "--- after_save" }
    after_create { tracer << "--- after_create" }
    after_update { tracer << "--- after_update" }
    after_rollback { tracer << "--- after_rollback" }
    after_commit { tracer << "--- after_commit" }
  end

  test "when persisted, #save causes (before|after)_(save|update) and after_commit callback to work" do
    tracer = []
    model = CallbackOrder.new(tracer, persisted: true)

    model.save
    expected =
      [
        "before_validation",
        "after_validation",
        "before_save",
        "before_update",
        "after_update",
        "after_save",
        "before_commit",
        "after_commit"
      ]
    assert { tracer == expected }
  end

  test "when not persisted, #save causes (before|after)_(save|create) and after_commit callback to work" do
    tracer = []
    model = CallbackOrder.new(tracer, persisted: false)

    model.save
    expected =
      [
        "before_validation",
        "after_validation",
        "before_save",
        "before_create",
        "after_create",
        "after_save",
        "before_commit",
        "after_commit"
      ]
    assert { tracer == expected }
  end

  test "when persisted, #update causes (before|after)_(save|update) and after_commit callback to work" do
    tracer = []
    model = CallbackOrder.new(tracer, persisted: true)

    model.update({})
    expected =
      [
        "before_validation",
        "after_validation",
        "before_save",
        "before_update",
        "after_update",
        "after_save",
        "before_commit",
        "after_commit"
      ]
    assert { tracer == expected }
  end

  test "when not persisted, #update causes (before|after)_(save|create) and after_commit callback to work" do
    tracer = []
    model = CallbackOrder.new(tracer, persisted: false)

    model.update({})
    expected =
      [
        "before_validation",
        "after_validation",
        "before_save",
        "before_create",
        "after_create",
        "after_save",
        "before_commit",
        "after_commit"
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
        "before_validation",
        "after_validation",
        "before_save",
        "before_create",
        "after_create",
        "after_save",
        "inner transsaction ends",
        "outer transsaction ends",
        "before_commit",
        "after_commit"
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
        "before_validation",
        "after_validation",
        "before_save",
        "before_create",
        "after_create",
        "after_save",
        "inner transsaction ends",
        "outer transsaction ends",
        "after_rollback"
      ]
    assert { tracer == expected }
  end

  test "when there is a nested model, the hook is executed in a nested manner." do
    tracer = []
    inner = Inner.new(name: "foo", email: "foo@example.com", tracer:)
    model = CallbackOrder.new(tracer, inner:)

    model.save
    expected =
      [
        "before_validation",
        "--- before_validation",
        "--- after_validation",
        "after_validation",
        "before_save",
        "before_create",
        "--- before_save",
        "--- before_create",
        "--- after_create",
        "--- after_save",
        "after_create",
        "after_save",
        "before_commit",
        "--- before_commit",
        "after_commit",
        "--- after_commit"
      ]
    assert { tracer == expected }
  end
end
