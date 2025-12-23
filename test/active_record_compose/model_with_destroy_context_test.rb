# frozen_string_literal: true

require "test_helper"
require "active_record_compose/model"

class ActiveRecordCompose::ModelWithDestroyContextTest < ActiveSupport::TestCase
  class WithDestroyContext < ActiveRecordCompose::Model
    def initialize(account, attributes = {})
      @account = account
      @profile = account.profile || account.build_profile
      super(attributes)
      models.push(account)
      push_profile_to_models
    end

    delegate_attribute :name, :email, to: :account
    delegate_attribute :firstname, :lastname, :age, to: :profile

    private

    attr_reader :account, :profile

    def push_profile_to_models = raise NotImplementedError

    def blank_profile? = firstname.blank? && lastname.blank? && age.blank?
  end

  test "model with destroy: true should be ignored (always valid) in validation" do
    model_class = Class.new(WithDestroyContext) do
      def push_profile_to_models
        models.push(profile, destroy: true)
      end
    end

    account = Account.create!(name: "foo", email: "foo@example.com")
    account.create_profile!(firstname: "bar", lastname: "baz", age: 45)
    model = model_class.new(account)
    model.name = "bar"
    model.email = "bar@example.com"
    model.firstname = nil
    model.lastname = nil
    model.age = nil

    assert { model.valid? }
  end

  test "models with destroy: true must be deleted by a #save operation" do
    model_class = Class.new(WithDestroyContext) do
      def push_profile_to_models
        models.push(profile, destroy: true)
      end
    end

    account = Account.create!(name: "foo", email: "foo@example.com")
    account.create_profile!(firstname: "bar", lastname: "baz", age: 45)
    model = model_class.new(account)
    model.name = "bar"
    model.email = "bar@example.com"

    assert_difference -> { Profile.count } => -1 do
      model.save!
    end

    account.reload
    assert { account.name == "bar" }
    assert { account.email == "bar@example.com" }
  end

  test "proc with arguments is passed to destroy, save and destroy can be controlled by result of that evaluation." do
    model_class = Class.new(WithDestroyContext) do
      def push_profile_to_models
        destroy = ->(p) { p.firstname.blank? && p.lastname.blank? && p.age.blank? }
        models.push(profile, destroy:)
      end
    end

    account = Account.create!(name: "foo", email: "foo@example.com")
    account.create_profile!(firstname: "bar", lastname: "baz", age: 45)
    model = model_class.new(account)
    model.assign_attributes(firstname: "qux", lastname: "quux", age: 36)

    assert_no_changes -> { Profile.count } do
      model.save!
    end
    account.profile.reload
    assert { account.profile.firstname == "qux" }
    assert { account.profile.lastname == "quux" }
    assert { account.profile.age == 36 }

    model.assign_attributes(firstname: nil, lastname: nil, age: nil)
    assert_difference -> { Profile.count } => -1 do
      model.save!
    end
  end

  test "proc is passed to destroy with no arguments, save and destroy can be controlled by result of its evaluation." do
    model_class = Class.new(WithDestroyContext) do
      def push_profile_to_models
        models.push(profile, destroy: -> { blank_profile? })
      end
    end

    account = Account.create!(name: "foo", email: "foo@example.com")
    account.create_profile!(firstname: "bar", lastname: "baz", age: 45)
    model = model_class.new(account)
    model.assign_attributes(firstname: "qux", lastname: "quux", age: 36)

    assert_no_changes -> { Profile.count } do
      model.save!
    end
    account.profile.reload
    assert { account.profile.firstname == "qux" }
    assert { account.profile.lastname == "quux" }
    assert { account.profile.age == 36 }

    model.assign_attributes(firstname: nil, lastname: nil, age: nil)
    assert_difference -> { Profile.count } => -1 do
      model.save!
    end
  end

  test "if method name symbol is passed to destroy, save and destroy can be controlled by result of its evaluation." do
    model_class = Class.new(WithDestroyContext) do
      def push_profile_to_models
        models.push(profile, destroy: :blank_profile?)
      end
    end

    account = Account.create!(name: "foo", email: "foo@example.com")
    account.create_profile!(firstname: "bar", lastname: "baz", age: 45)
    model = model_class.new(account)
    model.assign_attributes(firstname: "qux", lastname: "quux", age: 36)

    assert_no_changes -> { Profile.count } do
      model.save!
    end
    account.profile.reload
    assert { account.profile.firstname == "qux" }
    assert { account.profile.lastname == "quux" }
    assert { account.profile.age == 36 }

    model.assign_attributes(firstname: nil, lastname: nil, age: nil)
    assert_difference -> { Profile.count } => -1 do
      model.save!
    end
  end
end
