# frozen_string_literal: true

require "test_helper"
require "active_record_compose/delegate_attribute"

class ActiveRecordCompose::DelegateAttributeTest < ActiveSupport::TestCase
  class Dummy
    include ActiveModel::Attributes
    include ActiveRecordCompose::DelegateAttribute

    def initialize(data)
      @data = data
      super()
    end

    delegate_attribute :x, :y, to: :data

    private

    attr_reader :data
  end

  test "methods of reader and writer are defined" do
    data = Struct.new(:x, :y, :z, keyword_init: true).new
    data.x = "foo"
    object = Dummy.new(data)

    assert { data.x == "foo" }
    assert { object.x == "foo" }

    object.y = "bar"

    assert { data.y == "bar" }
    assert { object.y == "bar" }
  end

  test "definition declared in delegate must be included in attributes" do
    data = Struct.new(:x, :y, :z, keyword_init: true).new
    object = Dummy.new(data)
    object.x = "foo"
    object.y = "bar"

    assert { object.attributes == { "x" => "foo", "y" => "bar" } }
    assert { object.attribute_names == %w[x y] }
    assert { object.class.attribute_names == %w[x y] }
  end

  test "attributes to be transferred must be independent, even if there is an inheritance relationship" do
    data = Struct.new(:x, :y, :z, keyword_init: true).new
    data.x = "foo"
    data.y = "bar"
    data.z = "baz"

    o1 = Dummy.new(data)
    assert { o1.attributes == { "x" => "foo", "y" => "bar" } }
    assert { o1.attribute_names == %w[x y] }
    assert { o1.class.attribute_names == %w[x y] }

    subclass = Class.new(Dummy) do
      delegate_attribute :z, to: :data
    end
    o2 = subclass.new(data)
    assert { o2.attributes == { "x" => "foo", "y" => "bar", "z" => "baz" } }
    assert { o2.attribute_names == %w[x y z] }
    assert { o2.class.attribute_names == %w[x y z] }
  end
end
