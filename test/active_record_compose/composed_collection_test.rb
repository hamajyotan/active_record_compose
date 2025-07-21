# frozen_string_literal: true

require "test_helper"
require "active_record_compose/composed_collection"

class ActiveRecordCompose::ComposedCollectionTest < ActiveSupport::TestCase
  test "#empty should return true if the element is absent and false if the element is present" do
    collection = ActiveRecordCompose::ComposedCollection.new(nil)

    assert collection.empty?

    collection << Account.new

    assert_not collection.empty?
  end

  test "can be made empty by #clear" do
    collection = ActiveRecordCompose::ComposedCollection.new(nil)
    collection << Account.new
    collection.clear

    assert collection.empty?
  end

  test "#delete to exclude specific elements" do
    collection = ActiveRecordCompose::ComposedCollection.new(nil)
    account = Account.new
    profile = Profile.new
    collection << account << profile

    assert { collection.first == account }

    collection.delete(account)

    assert { collection.first == profile }
  end

  test "If the lock is in place, no operations with adverse side effects may be performed." do
    collection = ActiveRecordCompose::ComposedCollection.new(nil)
    account = Account.new
    profile = Profile.new
    collection << account

    collection.lock

    assert_raises(ActiveRecordCompose::LockedCollectionError) do
      collection.clear
    end
    assert_raises(ActiveRecordCompose::LockedCollectionError) do
      collection.push(profile)
    end
    assert_raises(ActiveRecordCompose::LockedCollectionError) do
      collection << profile
    end
    assert_raises(ActiveRecordCompose::LockedCollectionError) do
      collection.delete(account)
    end
  end

  test "If unlocked, operations with side effects can be performed." do
    collection = ActiveRecordCompose::ComposedCollection.new(nil)
    account = Account.new
    collection << account

    collection.lock

    assert_raises(ActiveRecordCompose::LockedCollectionError) do
      collection.clear
    end

    collection.unlock
    collection.clear
    assert collection.empty?
  end

  test "Locked while the block is being evaluated by with_lock" do
    collection = ActiveRecordCompose::ComposedCollection.new(nil)

    assert_not collection.locked?
    collection.with_lock do
      assert collection.locked?
    end
    assert_not collection.locked?
  end

  test "with_lock allows the block to be unlocked even while it is being evaluated." do
    collection = ActiveRecordCompose::ComposedCollection.new(nil)

    assert_not collection.locked?
    collection.with_lock do
      assert collection.locked?

      collection.unlock
      assert_not collection.locked?
    end
    assert_not collection.locked?
  end
end
