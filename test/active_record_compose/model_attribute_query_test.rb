# frozen_string_literal: true

require 'test_helper'
require 'active_record_compose/model'

class ActiveRecordCompose::ModelAttributeQueryTest < ActiveSupport::TestCase
  class ComposedModel < ActiveRecordCompose::Model
    def initialize(attributes = {})
      @account = Account.new
      @profile = account.build_profile
      super(attributes)
      models << account << profile
      self.attributes_method_calls = 0
    end

    attribute :foo
    attribute :bar
    attribute :baz
    attribute :qux
    delegate_attribute :name, :email, to: :account
    delegate_attribute :firstname, :lastname, :age, to: :profile

    attr_accessor :without_attribute, :attributes_method_calls

    def attributes
      self.attributes_method_calls += 1
      super
    end

    private

    attr_reader :account, :profile
  end

  test 'Methods with the suffix `?` are defined for each method declared as an attribute.' do
    model = ComposedModel.new

    assert model.respond_to?(:foo?)
    assert model.respond_to?(:bar?)
    assert model.respond_to?(:baz?)
    assert model.respond_to?(:qux?)
    assert model.respond_to?(:name?)
    assert model.respond_to?(:email?)
    assert model.respond_to?(:firstname?)
    assert model.respond_to?(:lastname?)
    assert model.respond_to?(:age?)
  end

  test 'Accessor methods that are not attributes do not have corresponding methods with a `?` suffix defined.' do
    model = ComposedModel.new

    assert_not model.respond_to?(:without_attribute?)
  end

  test 'If the value of the attribute is true, the query method returns true.' do
    assert ComposedModel.new(foo: true).foo?
  end

  test 'If the value of the attribute is false, the query method returns false.' do
    assert_not ComposedModel.new(foo: false).foo?
  end

  test 'If the value of the attribute is nil, the query method returns false.' do
    assert_not ComposedModel.new(foo: nil).foo?
  end

  test 'Returns true if a value has been provided for the attribute.' do
    model = ComposedModel.new(foo: 'Alice', bar: '', baz: [1], qux: [])

    assert model.foo?
    assert_not model.bar?
    assert model.baz?
    assert_not model.qux?
  end

  test 'If the value of the attribute is a number, it returns true when the value is non-zero.' do
    model = ComposedModel.new(foo: 123, bar: 0, baz: 456.7, qux: 0.0)

    assert model.foo?
    assert_not model.bar?
    assert model.baz?
    assert_not model.qux?
  end

  test 'attribute method is defined so that `#attributes` are not evaluated each time the query method is executed' do
    model = ComposedModel.new(foo: 123, bar: 0, baz: 456.7, qux: 0.0)

    assert_no_changes -> { model.attributes_method_calls } do
      model.foo?
      model.bar?
      model.qux?
      model.name?
      model.email?
    end
  end
end
