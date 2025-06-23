# frozen_string_literal: true

module ActiveRecordCompose
  module Callbacks
    extend ActiveSupport::Concern
    include ActiveModel::Validations::Callbacks

    included do
      define_model_callbacks :save
      define_model_callbacks :create
      define_model_callbacks :update
    end

    private

    def with_callbacks(&block) = run_callbacks(:save) { run_callbacks(callback_context, &block) }

    def callback_context = persisted? ? :update : :create
  end
end
