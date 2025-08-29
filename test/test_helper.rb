# frozen_string_literal: true

require "minitest/reporters"
Minitest::Reporters.use!

require "minitest/power_assert"

# Since Rails 7.1, test_case implicitly depends on deprecator.
require "active_support/deprecator"

require "active_support/test_case"

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "active_record_compose"

require_relative "support/schema"
require_relative "support/model"

require "minitest/autorun"
