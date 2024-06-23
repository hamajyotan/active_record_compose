# frozen_string_literal: true

module ActiveRecordCompose
  module TransactionSupport
    extend ActiveSupport::Concern
    include ActiveRecord::Transactions

    module ClassMethods
      def lease_connection
        if ar_class.respond_to?(:lease_connection)
          ar_class.lease_connection # steep:ignore
        else
          ar_class.connection
        end
      end

      def connection = ar_class.connection

      def with_connection(&) = ar_class.with_connection(&) # steep:ignore

      def composite_primary_key? = false

      private

      def ar_class = ActiveRecord::Base
    end

    def id = nil

    def trigger_transactional_callbacks? = true
    def restore_transaction_record_state(_force_restore_state = false) = nil # rubocop:disable Style/OptionalBooleanParameter
  end
end
