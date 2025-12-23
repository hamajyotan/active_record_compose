# frozen_string_literal: true

require "test_helper"

class BatchUpdateAndDeleteTest < ActiveSupport::TestCase
  # Here, we are testing cases where operations such as updating a certain model and
  # deleting another model are performed at once.
  #
  # As a specific example, we are considering something like user withdrawal processing.
  #
  # Assuming that existing activated users have one piece of data each in the
  # `Account`, `Profile`, and `Credential` models,
  # the following data updates will be implemented through the withdrawal process.
  #
  # 1. Enter a timestamp in the resigned_at attribute of the Account (mark for resignation)
  # 2. Delete the Profile (profiles) associated with the Account
  # 3. Delete the Credential (credentials) associated with the Account
  #
  # From this data manipulation event, we identify a resource called Resignation
  # and **create** it so that it can be resolved with normal Rails application operations.
  #
  # We are assuming cases where the following controllers are applied.
  #
  #     # app/controllers/resignations_controller.rb
  #     #
  #     class ResignationsController < ApplicationController
  #       before_action :require_login
  #
  #       def new
  #         @resignation = Resignation.new(current_user)
  #       end
  #
  #       def create
  #         @resignation = Resignation.new(current_user)
  #         if @resignation.update(resignation_params)
  #           redirect_to root_path, notice: "resigned."
  #         else
  #           render :new, status: :unprocessable_entity
  #         end
  #       end
  #
  #       private
  #
  #       def resignation_params
  #         params.expect(resignation: %i[resign_confirmation])
  #       end
  #     end
  #
  class Resignation < ActiveRecordCompose::Model
    def initialize(account)
      @account = account
      @profile = account.profile
      @credential = account.credential

      super()

      models << account
      models.push(profile, destroy: true)
      models.push(credential, destroy: true)
    end

    attribute :resign_confirmation, :boolean, default: false

    validates :resign_confirmation, acceptance: true

    before_validation :set_resigned_at
    after_commit :send_resigned_mail

    attr_accessor :send_resigned_mail_called

    private

    attr_reader :account, :profile, :credential

    def set_resigned_at
      account.resigned_at = Time.now
    end

    def send_resigned_mail
      # This is similar to sending an email notifying the user that their account has been deleted.
      #
      # ex. AccountMailer.with(account:).resigned.deliver_later
      self.send_resigned_mail_called = true
    end
  end

  setup do
    account = Account.create!(name: "alice-in-wonderland", email: "alice@example.com")
    account.create_profile!(firstname: "Alice", lastname: "Smish", age: 18)
    account.create_credential!(password: "P@ssW0rd", password_confirmation: "P@ssW0rd")
    @account = account

    @resignation = Resignation.new(@account)
  end

  test "When invalid, no updates will be made to the data, and error information can be obtained." do
    resignation_params = { resign_confirmation: false }

    assert_no_changes -> { @account.reload.resigned_at } do
      assert_no_difference -> { Profile.count }, -> { Credential.count } do
        assert_no_changes -> { @resignation.send_resigned_mail_called } do
          refute { @resignation.update(resignation_params) }
        end
      end
    end

    assert { @resignation.errors.count == 1 }
    assert { @resignation.errors.of_kind?(:resign_confirmation, :accepted) }
    assert { @resignation.errors.to_a == [ "Resign confirmation must be accepted" ] }
  end

  test "When valid, the data will be updated." do
    resignation_params = { resign_confirmation: true }

    assert_changes -> { @account.reload.resigned_at } do
      assert_difference -> { Profile.count } => -1, -> { Credential.count } => -1 do
        assert_changes -> { @resignation.send_resigned_mail_called } do
          assert @resignation.update(resignation_params)
        end
      end
    end
  end
end
