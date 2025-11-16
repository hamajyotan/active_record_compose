# frozen_string_literal: true

require "active_record"

require_relative "active_record_compose/version"
require_relative "active_record_compose/model"

# namespaces in gem `active_record_compose`.
#
# Most of the functionality resides in {ActiveRecordCompose::Model}.
#
module ActiveRecordCompose
end

require "active_record_compose/railtie" if defined?(::Rails::Railtie)
