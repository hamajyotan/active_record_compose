# frozen_string_literal: true

require 'active_support/test_case'

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'active_record_compose'

require_relative 'support/schema'
require_relative 'support/model'

require 'minitest/autorun'
