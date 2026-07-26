# frozen_string_literal: true

module ActiveRecordCompose
  module TransactionSupport
    # @private
    # steep:ignore:start

    # In older versions, the ActiveRecord::Transaction object is not passed to the block argument of #transaction.
    # So instead, we define a transaction object that can be evaluated equivalently.
    # This follow-up will no longer be necessary when support for Rails 7.1 is dropped.
    #
    class ActiveTransaction
      def initialize(transaction)
        @real_transaction = transaction
      end

      attr_reader :real_transaction

      def open? = !closed?

      def closed? = real_transaction&.state&.completed?

      def ==(other)
        return true if equal?(other)
        return false unless self.class == other.class

        real_transaction == other.real_transaction
      end

      def eql?(other)
        return true if equal?(other)
        return false unless self.class == other.class

        real_transaction.eql?(other.real_transaction)
      end

      def hash = real_transaction.hash
    end

    # steep:ignore:end
  end
end
