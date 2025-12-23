# frozen_string_literal: true

require "test_helper"

class ActiveRecordCompose::ModelLintTest < ActiveSupport::TestCase
  include ActiveModel::Lint::Tests

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

  setup do
    @model = ComposedModel.new
  end
end
