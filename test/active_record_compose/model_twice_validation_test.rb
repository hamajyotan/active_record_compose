# frozen_string_literal: true

require "test_helper"
require "active_record_compose/model"

class ActiveRecordCompose::ModelTwiceValidationTest < ActiveSupport::TestCase
  class FailureOnTwiceValidation < ActiveRecordCompose::Model
    def initialize(model = nil)
      super()
      models.push(model)
      @validation_count = 0
    end

    before_validation :increment_validation_count

    validates :validation_count, numericality: { less_than_or_equal_to: 1 }

    private

    attr_reader :validation_count

    def increment_validation_count
      @validation_count += 1
    end
  end

  test "FailureOnTwiceValidation model cannot be validated more than once." do
    model = FailureOnTwiceValidation.new
    assert model.valid?
    refute { model.valid? }
    refute { model.valid? }
  end

  test "Validation must be performed only once for the encompassing model." do
    inner_model = FailureOnTwiceValidation.new
    model = FailureOnTwiceValidation.new(inner_model)

    assert model.save
  end
end
