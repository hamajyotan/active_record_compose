# frozen_string_literal: true

require 'test_helper'
require 'active_record_compose/model'

class ActiveRecordCompose::ModelLegacyCallbackOrderTest < ActiveSupport::TestCase
  class CallbackOrder < ActiveRecordCompose::Model
    self.persisted_flag_callback_control = false

    def initialize(tracer)
      @tracer = tracer
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

    private

    attr_reader :tracer
  end

  test 'when #save, only #before_save, #after_save should work' do
    tracer = []
    model = CallbackOrder.new(tracer)

    model.save
    assert_equal tracer, [
      'before_save called',
      'after_save called',
      'before_commit called',
      'after_commit called',
    ]
  end

  test 'when #create, in addition to #before_save and #after_save, #before_create and #after_create must also work' do
    tracer = []
    model = CallbackOrder.new(tracer)

    model.create
    assert_equal tracer, [
      'before_save called',
      'before_create called',
      'after_create called',
      'after_save called',
      'before_commit called',
      'after_commit called',
    ]
  end

  test 'when #update, in addition to #before_save and #after_save, #before_update and #after_update must also work' do
    tracer = []
    model = CallbackOrder.new(tracer)

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
      'after_save called',
      'inner transsaction ends',
      'outer transsaction ends',
      'after_rollback called',
    ]
  end
end
