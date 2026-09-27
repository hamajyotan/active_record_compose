# frozen_string_literal: true

require "test_helper"

class ActiveRecordCompose::ModelConnectionTest < ActiveSupport::TestCase
  if ActiveRecord.version >= Gem::Version.new("7.2")
    test "provides a working database connection with with_connection" do
      assert_deprecated(ActiveRecordCompose.deprecator) do
        ActiveRecordCompose::Model.with_connection do |conn|
          assert_nothing_raised { conn.execute("SELECT 1") }
        end
      end
    end

    test "provides a working leased database connection" do
      assert_deprecated(ActiveRecordCompose.deprecator) do
        conn = ActiveRecordCompose::Model.lease_connection
        assert_nothing_raised { conn.execute("SELECT 1") }
      end
    end
  end

  test "provides a working database connection" do
    assert_deprecated(ActiveRecordCompose.deprecator) do
      conn = ActiveRecordCompose::Model.connection
      assert_nothing_raised { conn.execute("SELECT 1") }
    end
  end
end
