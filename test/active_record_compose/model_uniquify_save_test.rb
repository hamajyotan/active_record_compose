# frozen_string_literal: true

require "test_helper"

class ActiveRecordCompose::ModelUniquifySaveTest < ActiveSupport::TestCase
  class Inner
    include ActiveModel::Model
    include ActiveModel::Validations::Callbacks
    include ActiveModel::Attributes

    define_model_callbacks :save
    define_model_callbacks :destroy

    attribute :save_count, :integer, default: 0
    attribute :destroy_count, :integer, default: 0

    after_save { _1.save_count += 1 }
    after_destroy { _1.destroy_count += 1 }

    def save(**) = run_callbacks(:save) { true }
    def save!(**) = run_callbacks(:save) { true }
    def destroy(**) = run_callbacks(:destroy) { true }
    def destroy!(**) = run_callbacks(:destroy) { true }
  end

  test "Even if the same object is added multiple times, it will only be saved once." do
    inner = Inner.new
    klass =
      Class.new(ActiveRecordCompose::Model) do
        def initialize(*__models)
          super()
          __models.each { models << _1 }
        end
      end

    model = klass.new(inner, inner)
    model.save!

    assert { inner.save_count == 1 }
  end

  test "A save is performed once for each object added" do
    inner = Inner.new
    other_inner = Inner.new
    klass =
      Class.new(ActiveRecordCompose::Model) do
        def initialize(*__models)
          super()
          __models.each { models << _1 }
        end
      end

    model = klass.new(inner, inner, other_inner, other_inner)
    model.save!

    assert { inner.save_count == 1 }
    assert { other_inner.save_count == 1 }
  end

  test "Even if the same object is added in different ways, it is only saved once." do
    inner = Inner.new
    klass =
      Class.new(ActiveRecordCompose::Model) do
        def initialize(model)
          super()
          models.push(model)
          models << model
        end
      end

    model = klass.new(inner)
    model.save!

    assert { inner.save_count == 1 }
  end

  test "Even if the :if options are different, if the evaluation results are the same, it will be considered the same operation." do
    inner = Inner.new
    klass =
      Class.new(ActiveRecordCompose::Model) do
        def initialize(model)
          super()
          models.push(model)
          models.push(model, if: :always_true)
          models.push(model, if: :always_true_2)
          models.push(model, if: -> { always_true })
        end

        def always_true = true
        def always_true_2 = true
      end

    model = klass.new(inner)
    model.save!

    assert { inner.save_count == 1 }
  end

  test "If the evaluation result of the if option is falsy, it will be ignored and will not be saved anyway." do
    inner = Inner.new
    klass =
      Class.new(ActiveRecordCompose::Model) do
        def initialize(model)
          super()
          models.push(model)
          models.push(model, if: -> { true })
          models.push(model, if: :always_false)
          models.push(model, if: :always_false_2)
          models.push(model, if: -> { [ true, false ].sample })
        end

        def always_false = false
        def always_false_2 = false
      end

    model = klass.new(inner)
    model.save!

    assert { inner.save_count == 1 }
  end

  test "Treated as separate operations depending on the evaluation result of the :destroy option." do
    inner = Inner.new
    klass =
      Class.new(ActiveRecordCompose::Model) do
        def initialize(model)
          super()
          models.push(model)
          models.push(model, destroy: true)
          models.push(model, destroy: false)
          models.push(model, destroy: -> { always_true })
        end

        def always_true = true
      end

    model = klass.new(inner)
    model.save!

    assert { inner.save_count == 1 }
    assert { inner.destroy_count == 1 }
  end
end
