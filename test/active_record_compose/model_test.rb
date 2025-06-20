# frozen_string_literal: true

require "test_helper"
require "active_record_compose/model"

class ActiveRecordCompose::ModelTest < ActiveSupport::TestCase
  class ComposedModel < ActiveRecordCompose::Model
    def initialize(account = Account.new)
      @account = account
      @profile = account.then { _1.profile || _1.build_profile }
      super()
      models << account << profile
    end

    delegate_attribute :name, :email, to: :account
    delegate_attribute :firstname, :lastname, :age, to: :profile

    private

    attr_reader :account, :profile
  end

  test "when invalid, an error object is set" do
    model = ComposedModel.new
    model.assign_attributes(invalid_attributes)

    assert model.invalid?
    assert model.errors.of_kind?(:name, :blank)
    assert model.errors.of_kind?(:firstname, :too_long)
    assert model.errors.of_kind?(:lastname, :too_long)
    assert model.errors.of_kind?(:age, :greater_than_or_equal_to)
    expected_error_messasges =
      [
        "Name can't be blank",
        "Email can't be blank",
        "Firstname is too long (maximum is 32 characters)",
        "Lastname is too long (maximum is 32 characters)",
        "Age must be greater than or equal to 0"
      ]
    assert { model.errors.to_a.sort == expected_error_messasges.sort }
  end

  test "when invalid, models are not saved." do
    model = ComposedModel.new
    model.assign_attributes(invalid_attributes)

    assert_not model.save
    e = assert_raises(ActiveRecord::RecordInvalid) { model.save! }
    assert { model == e.record }
  end

  test "when valid assign, #save is performed for each model entered in models by save." do
    model = ComposedModel.new
    model.assign_attributes(valid_attributes)

    assert model.valid?
    assert_difference -> { Account.count } => 1, -> { Profile.count } => 1 do
      model.save!
    end
  end

  test "pushed nil object must be ignored." do
    model_class = Class.new(ComposedModel) do
      def push_falsy_object_to_models = models << nil
    end
    model = model_class.new
    model.assign_attributes(valid_attributes)
    model.push_falsy_object_to_models

    assert model.valid?
    assert model.save
  end

  test "errors made during internal model storage are propagated externally." do
    account_with_bang = Class.new(Account) do
      after_save { raise "bang!" }
    end

    model = ComposedModel.new(account_with_bang.new)
    model.assign_attributes(valid_attributes)

    assert_raises(RuntimeError, "bang!!") { model.save }
    assert_raises(RuntimeError, "bang!!") { model.save! }
  end

  test "RecordInvalid errors that occur during internal saving of the model are propagated externally only if #save!" do
    model_class = Class.new(ComposedModel) do
      after_save { Account.create!(name: nil, email: nil) }
    end
    model = model_class.new
    model.assign_attributes(valid_attributes)

    assert_not model.save
    assert_raises(ActiveRecord::RecordInvalid) do
      model.save!
    end
  end

  test "attributes defined by .delegate_attributes should be included" do
    model_class = Class.new(ComposedModel) do
      attribute :foo
    end
    model = model_class.new
    model.assign_attributes(valid_attributes)
    model.foo = "foobar"

    assert { model.attributes == { "foo" => "foobar", **valid_attributes.stringify_keys } }
  end

  private

  def valid_attributes
    {
      name: "foo",
      email: "foo@example.com",
      firstname: "bar",
      lastname: "baz",
      age: 45
    }
  end

  def invalid_attributes
    {
      name: nil,
      email: nil,
      firstname: "*" * 33,
      lastname: "*" * 33,
      age: -1
    }
  end
end
