# frozen_string_literal: true

require "test_helper"
require "active_record_compose/model"

class ActiveRecordCompose::ModelUpdatableTimingToModelsTest < ActiveSupport::TestCase
  test "No updates can be made to models in the before_save hook." do
    klass =
      Class.new(ActiveRecordCompose::Model) do
        def initialize(account)
          @account = account
          super()
        end

        attr_reader :account

        before_save { models << account }
      end
    model = klass.new(new_valid_account)

    assert_no_changes -> { Account.count } do
      assert_raises(ActiveRecordCompose::LockedCollectionError, "Collection is locked and cannot be changed.") do
        model.save
      end
    end
  end

  test "No updates can be made to models in the before_create hook." do
    klass =
      Class.new(ActiveRecordCompose::Model) do
        def initialize(account)
          @account = account
          super()
        end

        attr_reader :account

        before_create { models << account }
      end
    model = klass.new(new_valid_account)

    assert_no_changes -> { Account.count } do
      assert_raises(ActiveRecordCompose::LockedCollectionError, "Collection is locked and cannot be changed.") do
        model.save
      end
    end
  end

  test "No updates can be made to models in the before_update hook." do
    klass =
      Class.new(ActiveRecordCompose::Model) do
        def initialize(account)
          @account = account
          super()
        end

        attr_reader :account

        before_update { models << account }

        def persisted? = true # for fire after_update hook.
      end
    model = klass.new(new_valid_account)

    assert_no_changes -> { Account.count } do
      assert_raises(ActiveRecordCompose::LockedCollectionError, "Collection is locked and cannot be changed.") do
        model.save
      end
    end
  end

  test "Models can be updated in the after_save hook. However, the added models are not affected by the change." do
    klass =
      Class.new(ActiveRecordCompose::Model) do
        def initialize(account)
          @account = account
          super()
        end

        attr_reader :account

        after_save { models << account }
      end
    model = klass.new(new_valid_account)

    assert_no_changes -> { Account.count } do
      assert model.save
    end
  end

  test "Models can be updated in the after_create hook. However, the added models are not affected by the change." do
    klass =
      Class.new(ActiveRecordCompose::Model) do
        def initialize(account)
          @account = account
          super()
        end

        attr_reader :account

        after_create { models << account }
      end
    model = klass.new(new_valid_account)

    assert_no_changes -> { Account.count } do
      assert model.save
    end
  end

  test "Models can be updated in the after_update hook. However, the added models are not affected by the change." do
    klass =
      Class.new(ActiveRecordCompose::Model) do
        def initialize(account)
          @account = account
          super()
        end

        attr_reader :account

        after_update { models << account }

        def persisted? = true # for fire after_update hook.
      end
    model = klass.new(new_valid_account)

    assert_no_changes -> { Account.count } do
      assert model.save
    end
  end

  private

  def new_valid_account
    Account.new(name: "foo", email: "foo@example.com")
  end
end
