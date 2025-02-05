# frozen_string_literal: true

require 'test_helper'
require 'active_record_compose/composed_collection'

class ActiveRecordCompose::ComposedCollectionTest < ActiveSupport::TestCase
  test '#empty should return true if the element is absent and false if the element is present' do
    collection = ActiveRecordCompose::ComposedCollection.new(nil)

    assert collection.empty?

    collection << Account.new

    assert_not collection.empty?
  end

  test 'can be made empty by #clear' do
    collection = ActiveRecordCompose::ComposedCollection.new(nil)
    collection << Account.new
    collection.clear

    assert collection.empty?
  end

  test '#delete to exclude specific elements' do
    collection = ActiveRecordCompose::ComposedCollection.new(nil)
    account = Account.new
    profile = Profile.new
    collection << account << profile

    assert_equal collection.first, account

    collection.delete(account)

    assert_equal collection.first, profile
  end
end
