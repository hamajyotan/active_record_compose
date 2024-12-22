# frozen_string_literal: true

require 'test_helper'
require 'active_record_compose/delegate_attribute'

class ActiveRecordCompose::InnerModelTest < ActiveSupport::TestCase
  class Dummy
    include ActiveRecordCompose::DelegateAttribute

    def initialize(data)
      @data = data
    end

    delegate_attribute :x, :y, to: :data

    private

    attr_reader :data
  end

  test 'methods of reader and writer are defined' do
    data = Struct.new(:x, :y, :z, keyword_init: true).new
    data.x = 'foo'
    object = Dummy.new(data)

    assert_equal data.x, 'foo'
    assert_equal object.x, 'foo'

    object.y = 'bar'

    assert_equal data.y, 'bar'
    assert_equal object.y, 'bar'
  end

  test 'definition declared in delegate must be included in attributes' do
    data = Struct.new(:x, :y, :z, keyword_init: true).new
    object = Dummy.new(data)
    object.x = 'foo'
    object.y = 'bar'

    assert_equal object.attributes, { 'x' => 'foo', 'y' => 'bar' }
  end
end
