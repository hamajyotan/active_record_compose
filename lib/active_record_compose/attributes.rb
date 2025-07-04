# frozen_string_literal: true

require_relative "attributes/querying"
require_relative "delegate_attribute"

module ActiveRecordCompose
  module Attributes
    extend ActiveSupport::Concern

    included do
      include ActiveModel::Attributes
      include Querying
      include ActiveRecordCompose::DelegateAttribute
    end
  end
end
