# frozen_string_literal: true

require "test_helper"

class ActiveRecordCompose::ModelContextTest < ActiveSupport::TestCase
  class ComposedModel < ActiveRecordCompose::Model
    def initialize(attributes)
      @account = Account.new
      @profile = account.then { _1.profile || _1.build_profile }
      super
      models << account << profile
    end

    attribute :accept, :boolean, default: true
    validates :accept, presence: true, on: :education

    delegate_attribute :name, :email, to: :account
    delegate_attribute :firstname, :lastname, :age, to: :profile

    private

    attr_reader :account, :profile
  end

  test "#valid without `:context` Validations with `:on` do not work." do
    assert { new_model.valid? }
    assert { new_model(accept: false).valid? }
  end

  test "if `context` is specified, then the `:on` validation on the model will work on #valid? operation." do
    assert { new_model.valid?(:education) }

    model = new_model(accept: false)
    assert { model.invalid?(:education) }
    assert { model.errors.of_kind?(:accept, :blank) }
    assert { model.errors.to_a == [ "Accept can't be blank" ] }
  end

  test "if `context` is specified, then the `:on` validation on inner models will work on #valid? operation." do
    assert { new_model.valid?(:education) }

    model = new_model(email: "foo@example.com", age: 99)
    assert { model.invalid?(:education) }
    assert { model.errors.of_kind?(:email, :invalid) }
    assert { model.errors.of_kind?(:age, :less_than_or_equal_to) }
    expected_error_messasges =
      [
        "Age must be less than or equal to 18",
        "Email is invalid"
      ]
    assert { model.errors.to_a.sort == expected_error_messasges.sort }
  end

  test "#save without the `:context` option does not affect the `:on` specified validation." do
    assert_difference -> { Account.count } => 1, -> { Profile.count } => 1 do
      assert { new_model.save }
    end
    assert_difference -> { Account.count } => 1, -> { Profile.count } => 1 do
      new_model(accept: false).save
    end
  end

  test "#save with `:context` option means that the validation with `:on` on the model works." do
    assert_difference -> { Account.count } => 1, -> { Profile.count } => 1 do
      assert { new_model.save(context: :education) }
    end

    assert_no_changes -> { Account.count }, -> { Profile.count } do
      model = new_model(accept: false)

      refute { model.save(context: :education) }
      assert { model.errors.of_kind?(:accept, :blank) }
      assert { model.errors.to_a == [ "Accept can't be blank" ] }
    end
  end

  test "#save with `:context` option means that the validation with `:on` on the inner models works." do
    assert_difference -> { Account.count } => 1, -> { Profile.count } => 1 do
      assert { new_model.save(context: :education) }
    end

    assert_no_changes -> { Account.count }, -> { Profile.count } do
      model = new_model(email: "foo@example.com", age: 99)

      refute { model.save(context: :education) }
      assert { model.errors.of_kind?(:email, :invalid) }
      assert { model.errors.of_kind?(:age, :less_than_or_equal_to) }
      assert { model.errors.to_a.sort == [ "Age must be less than or equal to 18", "Email is invalid" ].sort }
    end
  end

  private

  def new_model(attributes = {}) = ComposedModel.new(valid_attributes.merge(attributes))

  def valid_attributes
    {
      accept: true,
      name: "foo",
      email: "foo@example.edu",
      firstname: "bar",
      lastname: "baz",
      age: 12
    }
  end
end
