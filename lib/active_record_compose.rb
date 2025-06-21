# frozen_string_literal: true

require 'active_record'

require_relative 'active_record_compose/version'
require_relative 'active_record_compose/model'

module ActiveRecordCompose
end

if ActiveRecordCompose::VERSION == '0.8.1'
  unless ENV['ACTIVE_RECORD_COMPOSE_SILENCE_DEPRECATION'] # rubocop:disable Style/SoleNestedConditional
    warn <<~WARN

      [DEPRECATION] You are using active_record_compose version 0.8.1, which is deprecated.
      Please upgrade to the latest version.
      See: https://github.com/hamajyotan/active_record_compose/blob/v0.8.1/UPGRADE.md

    WARN
  end
end
