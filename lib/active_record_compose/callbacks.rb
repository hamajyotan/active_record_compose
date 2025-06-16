# frozen_string_literal: true

module ActiveRecordCompose
  module Callbacks
    extend ActiveSupport::Concern

    included do
      include ActiveModel::Validations::Callbacks

      define_model_callbacks :save
      define_model_callbacks :create
      define_model_callbacks :update
    end

    private

    def with_callbacks(&block) = run_callbacks(:save) { run_callbacks(callback_context, &block) }

    def callback_context = persisted? ? :update : :create
  end
end
