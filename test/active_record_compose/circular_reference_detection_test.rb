# frozen_string_literal: true

require "test_helper"

class CircularReferenceDetectionTest < ActiveSupport::TestCase
  test "cannot add self to models" do
    m1 = klass.new

    m1.model = m1
    assert_raises(ActiveRecordCompose::CircularReferenceDetected) do
      assert { m1.save }
    end
  end

  test "there must be no circular references from objects contained in models" do
    inner = klass.new
    middle = klass.new(model: inner)
    outer = klass.new(model: middle)

    inner.model = outer

    assert_raises(ActiveRecordCompose::CircularReferenceDetected) do
      assert { outer.save }
    end
  end

  test "if the objects in the model do not have circular references, no exceptions will occur." do
    inner = klass.new
    middle = klass.new(model: inner)
    outer = klass.new(model: middle)

    assert { outer.save }
  end

  private

  def klass
    @klass ||=
      Class.new(ActiveRecordCompose::Model) do
        attribute :model
        before_validation { models << model }
      end
  end
end
