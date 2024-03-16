# frozen_string_literal: true

module ActiveRecordCompose
  module TransactionSupport
    extend ActiveSupport::Concern
    include ActiveRecord::Transactions

    module ClassMethods
      def lease_connection
        if ActiveRecord::Base.respond_to?(:lease_connection)
          __skip__ = ActiveRecord::Base.lease_connection
        else
          ActiveRecord::Base.connection
        end
      end

      def connection = ActiveRecord::Base.connection

      def composite_primary_key? = false
    end

    def id = nil

    def trigger_transactional_callbacks? = true
    def restore_transaction_record_state(_force_restore_state = false) = nil # rubocop:disable Style/OptionalBooleanParameter
  end
end
