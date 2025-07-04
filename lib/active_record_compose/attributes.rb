# frozen_string_literal: true

require_relative "attribute_querying"
require_relative "delegate_attribute"

module ActiveRecordCompose
  module Attributes
    extend ActiveSupport::Concern

    included do
      include ActiveModel::Attributes
      include ActiveRecordCompose::AttributeQuerying
      include ActiveRecordCompose::DelegateAttribute
    end
  end
end
