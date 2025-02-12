# frozen_string_literal: true

require 'test_helper'
require 'active_record_compose/model'

class ActiveRecordCompose::ModelCallbackOrderTest < ActiveSupport::TestCase
  class CallbackOrder < ActiveRecordCompose::Model
    def initialize(tracer, persisted: false)
      @tracer = tracer
      @persisted = persisted
      super()
    end

    before_save { tracer << 'before_save called' }
    before_create { tracer << 'before_create called' }
    before_update { tracer << 'before_update called' }
    before_commit { tracer << 'before_commit called' }
    after_save { tracer << 'after_save called' }
    after_create { tracer << 'after_create called' }
    after_update { tracer << 'after_update called' }
    after_rollback { tracer << 'after_rollback called' }
    after_commit { tracer << 'after_commit called' }

    def persisted? = !!@persisted

    private

    attr_reader :tracer
  end

  test 'when persisted, #save causes (before|after)_(save|update) and after_commit callback to work' do
    tracer = []
    model = CallbackOrder.new(tracer, persisted: true)

    model.save
    assert_equal tracer, [
      'before_save called',
      'before_update called',
      'after_update called',
      'after_save called',
      'before_commit called',
      'after_commit called',
    ]
  end

  test 'when not persisted, #save causes (before|after)_(save|create) and after_commit callback to work' do
    tracer = []
    model = CallbackOrder.new(tracer, persisted: false)

    model.save
    assert_equal tracer, [
      'before_save called',
      'before_create called',
      'after_create called',
      'after_save called',
      'before_commit called',
      'after_commit called',
    ]
  end

  test '#create must not be executable' do
    model = CallbackOrder.new([])

    exception = assert_raises StandardError do
      model.create
    end
    assert_equal exception.message, <<~MESSAGE.chomp
      `#create` cannot be called. The context for creation or update is determined by the `#persisted` flag.
    MESSAGE
  end

  test 'when persisted, #update causes (before|after)_(save|update) and after_commit callback to work' do
    tracer = []
    model = CallbackOrder.new(tracer, persisted: true)

    model.update
    assert_equal tracer, [
      'before_save called',
      'before_update called',
      'after_update called',
      'after_save called',
      'before_commit called',
      'after_commit called',
    ]
  end

  test 'when not persisted, #update causes (before|after)_(save|create) and after_commit callback to work' do
    tracer = []
    model = CallbackOrder.new(tracer, persisted: false)

    model.update
    assert_equal tracer, [
      'before_save called',
      'before_create called',
      'after_create called',
      'after_save called',
      'before_commit called',
      'after_commit called',
    ]
  end

  test 'execution of (before|after)_commit hook is delayed until after the database commit.' do
    tracer = []
    model = CallbackOrder.new(tracer)

    ActiveRecord::Base.transaction do
      tracer << 'outer transsaction starts'
      ActiveRecord::Base.transaction do
        tracer << 'inner transsaction starts'
        model.save
        tracer << 'inner transsaction ends'
      end
      tracer << 'outer transsaction ends'
    end

    assert_equal tracer, [
      'outer transsaction starts',
      'inner transsaction starts',
      'before_save called',
      'before_create called',
      'after_create called',
      'after_save called',
      'inner transsaction ends',
      'outer transsaction ends',
      'before_commit called',
      'after_commit called',
    ]
  end

  test 'execution of after_rollback hook is delayed until after the database rollback.' do
    tracer = []
    model = CallbackOrder.new(tracer)

    ActiveRecord::Base.transaction do
      tracer << 'outer transsaction starts'
      ActiveRecord::Base.transaction do
        tracer << 'inner transsaction starts'
        model.save
        tracer << 'inner transsaction ends'
      end
      tracer << 'outer transsaction ends'
      raise ActiveRecord::Rollback
    end

    assert_equal tracer, [
      'outer transsaction starts',
      'inner transsaction starts',
      'before_save called',
      'before_create called',
      'after_create called',
      'after_save called',
      'inner transsaction ends',
      'outer transsaction ends',
      'after_rollback called',
    ]
  end
end
