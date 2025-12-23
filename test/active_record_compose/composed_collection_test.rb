# frozen_string_literal: true

require "test_helper"
require "active_record_compose/composed_collection"

class ActiveRecordCompose::ComposedCollectionTest < ActiveSupport::TestCase
  test "#empty should return true if the element is absent and false if the element is present" do
    collection = ActiveRecordCompose::ComposedCollection.new(nil)

    assert { collection.empty? }

    collection << Account.new

    refute { collection.empty? }
  end

  test "can be made empty by #clear" do
    collection = ActiveRecordCompose::ComposedCollection.new(nil)
    collection << Account.new
    collection.clear

    assert { collection.empty? }
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

  test "#delete will delete the specified model regardless of the options used when adding it" do
    collection = ActiveRecordCompose::ComposedCollection.new(nil)
    account = Account.new
    profile = Profile.new
    collection.push(account, destroy: false)
    collection.push(profile)
    collection.push(account, destroy: true)

    assert { collection.first == account }
    assert { collection.count == 3 }

    collection.delete(account)

    assert { collection.first == profile }
    assert { collection.count == 1 }
  end
end
