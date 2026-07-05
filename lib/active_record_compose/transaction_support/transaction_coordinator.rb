# frozen_string_literal: true

require "set"

module ActiveRecordCompose
  module TransactionSupport
    # @private
    class TransactionCoordinator
      def add_transaction(active_transaction)
        transactions << active_transaction
      end

      # The before_commit callback is controlled so that
      # it runs just before the outermost transaction commits,
      # but not just before any inner transactions commit.
      #
      def on_before_comitted
        return if @_before_committed_called

        yield
        @_before_committed_called = true
      end

      # It processes after_commit/after_rollback only immediately
      # after all transactions are closed.
      #
      def on_after_transaction
        return unless all_finished?

        with_transaction_cleanup { yield }
      end

      private

      def with_transaction_cleanup
        yield
      ensure
        @_before_committed_called = false
        transactions.reject! { _1.closed? }
      end

      def all_finished? = transactions.all? { _1.closed? }

      def transactions = @transactions ||= Set.new
    end
  end
end
