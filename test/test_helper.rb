# frozen_string_literal: true

require 'minitest/reporters'
Minitest::Reporters.use!

# Since Rails 7.1, test_case implicitly depends on deprecator.
# Also, deprecator does not exist before 7.0
begin
  require 'active_support/deprecator'
rescue LoadError
  # do nothing.
end

require 'active_support/test_case'

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'active_record_compose'

require_relative 'support/schema'
require_relative 'support/model'

require 'minitest/autorun'
