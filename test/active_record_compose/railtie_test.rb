# frozen_string_literal: true

require "test_helper"

class ActiveRecordCompose::RailtieTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::Isolation

  test "The filter_parameters settings in the rails application are reflected in the filter_attributes" do
    require "fake_app/application"

    assert_changes -> { ActiveRecordCompose::Model.filter_attributes } do
      FakeApp.initialize!

      assert { FakeApp.config.filter_parameters.size > 0 }
      assert { (FakeApp.config.filter_parameters - ActiveRecordCompose::Model.filter_attributes).empty? }
    end
  end
end
