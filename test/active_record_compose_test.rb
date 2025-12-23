# frozen_string_literal: true

require "test_helper"

class ActiveRecordComposeTest < ActiveSupport::TestCase
  test "that it has a version number" do
    assert { ActiveRecordCompose::VERSION }
  end
end
