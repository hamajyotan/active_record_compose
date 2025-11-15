# frozen_string_literal: true

require "rails"
require "active_record_compose"
require "active_record/railtie"

module ActiveRecordCompose
  class Railtie < Rails::Railtie
    initializer "active_record_compose.set_filter_attributes", after: "active_record.set_filter_attributes" do
      ActiveSupport.on_load(:active_record) do
        ActiveRecordCompose::Model.filter_attributes += ActiveRecord::Base.filter_attributes
      end
    end
  end
end
