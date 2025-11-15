# frozen_string_literal: true

require "active_record/railtie"
require "active_record_compose/railtie"

class FakeApp < Rails::Application
  config.secret_key_base = "test_secret_key_base"
  config.eager_load = false
  config.root = __dir__
  config.logger = Logger.new($stdout)

  config.filter_parameters += %i[password sensitive]
end
