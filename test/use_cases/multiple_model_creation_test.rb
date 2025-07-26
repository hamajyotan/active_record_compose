# frozen_string_literal: true

require "test_helper"

class MultipleModelCreationTest < ActiveSupport::TestCase
  # Here, we are testing the batch registration of multiple models as a single model.
  #
  # As a concrete example,
  # we are considering an operation such as user registration for a certain service.
  #
  # The model that constitutes the user is composed of `Account`, `Profile`, and `Credential`.
  # In other words, it is divided into multiple tables,
  # and it is required to register them all at once with a single “user registration” operation.
  #
  # We define this data operation event as a resource called Registration and create it as a normal Rails application operation.
  #
  # We are assuming cases where the following controllers are applied.
  #
  #     # app/controllers/registrations_controller.rb
  #     #
  #     class RegistrationsController < ApplicationController
  #       def new
  #         @registration = Registration.new
  #       end
  #
  #       def create
  #         @registration = Registration.new
  #         if @registration.update(registration_params)
  #           redirect_to root_path, notice: "registered."
  #         else
  #           render :new, status: :unprocessable_entity
  #         end
  #       end
  #
  #       private
  #
  #       def registration_params
  #         params.expect(registration: %i[
  #           name email firstname lastname age
  #           password password_confirmation terms_of_service
  #         ])
  #       end
  #     end
  #
  class Registration < ActiveRecordCompose::Model
    def initialize
      @account = Account.new
      @profile = account.build_profile
      @credential = account.build_credential

      super

      models << account << profile << credential
    end

    delegate_attribute :name, :email, to: :account
    delegate_attribute :firstname, :lastname, :age, to: :profile
    delegate_attribute :password, :password_confirmation, to: :credential
    attribute :terms_of_service, :boolean, default: false

    validates :password_confirmation, presence: true
    validates :terms_of_service, acceptance: true

    after_commit :send_registered_mail

    attr_accessor :send_registered_mail_called

    private

    attr_reader :account, :profile, :credential

    def send_registered_mail
      # It is similar to sending an email to notify users
      # that their registration has been completed after they register.
      #
      # ex. AccountMailer.with(account:).registered.deliver_later
      self.send_registered_mail_called = true
    end
  end

  setup do
    @registration = Registration.new
  end

  test "When invalid, no updates will be made to the data, and error information can be obtained." do
    registration_params = {
      name: "alice-in-wonderland",
      email: "alice@example.com",
      firstname: "Alice",
      lastname: "Smith",
      age: 18,
      password: nil,
      password_confirmation: nil,
      terms_of_service: false
    }

    assert_not @registration.update(registration_params)

    assert { @registration.errors.count == 3 }
    assert @registration.errors.of_kind?(:password, :blank)
    assert @registration.errors.of_kind?(:password_confirmation, :blank)
    assert @registration.errors.of_kind?(:terms_of_service, :accepted)
    assert @registration.errors.to_a.include?("Password can't be blank")
    assert @registration.errors.to_a.include?("Password confirmation can't be blank")
    assert @registration.errors.to_a.include?("Terms of service must be accepted")

    registration_params = {
      name: "alice-in-wonderland",
      email: "alice@example.com",
      firstname: "Alice",
      lastname: "Smith",
      age: 18,
      password: "P@ssW0rd",
      password_confirmation: nil,
      terms_of_service: true
    }

    assert_not @registration.update(registration_params)

    assert { @registration.errors.count == 1 }
    assert @registration.errors.of_kind?(:password_confirmation, :blank)
    assert @registration.errors.to_a.include?("Password confirmation can't be blank")

    registration_params = {
      name: "alice-in-wonderland",
      email: "alice@example.com",
      firstname: "Alice",
      lastname: "Smith",
      age: 18,
      password: "P@ssW0rd",
      password_confirmation: "P@ssW0rd!!!",
      terms_of_service: true
    }

    assert_not @registration.update(registration_params)

    assert { @registration.errors.count == 1 }
    assert @registration.errors.of_kind?(:password_confirmation, :confirmation)
    assert @registration.errors.to_a.include?("Password confirmation doesn't match Password")
  end

  test "When all the attributes required for registration are present, data operations required for resigning are completed." do
    registration_params = {
      name: "alice-in-wonderland",
      email: "alice@example.com",
      firstname: "Alice",
      lastname: "Smith",
      age: 18,
      password: "P@ssW0rd",
      password_confirmation: "P@ssW0rd",
      terms_of_service: true
    }

    assert_difference -> { Account.count } => 1, -> { Profile.count } => 1, -> { Credential.count } => 1 do
      assert_changes -> { @registration.send_registered_mail_called } do
        assert @registration.update(registration_params)
      end
    end
  end
end
