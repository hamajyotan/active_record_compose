# frozen_string_literal: true

module ActiveRecordCompose
  # @private
  module TransactionSupport
    extend ActiveSupport::Concern
    include ActiveRecord::Transactions

    included do
      # ActiveRecord::Transactions is defined so that methods such as save,
      # destroy and touch are wrapped with_transaction_returning_status.
      # However, ActiveRecordCompose::Model does not support destroy and touch, and
      # we want to keep these operations as undefined behavior, so we remove the definition here.
      undef_method :destroy, :touch
    end

    module ClassMethods
      delegate :with_connection, :lease_connection, to: :ar_class

      # In ActiveRecord, it is soft deprecated.
      delegate :connection, to: :ar_class

      def composite_primary_key? = false # steep:ignore

      private

      def ar_class = ActiveRecord::Base
    end

    def id = nil

    def trigger_transactional_callbacks? = true
    def restore_transaction_record_state(_force_restore_state = false) = nil
  end
end
