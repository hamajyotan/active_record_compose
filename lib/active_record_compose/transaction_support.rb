# frozen_string_literal: true

module ActiveRecordCompose
  # @private
  module TransactionSupport
    extend ActiveSupport::Concern

    included do
      define_callbacks :commit, :rollback, :before_commit, scope: [ :kind, :name ]
    end

    module ClassMethods
      delegate :with_connection, :lease_connection, to: :ar_class

      # In ActiveRecord, it is soft deprecated.
      delegate :connection, to: :ar_class

      def before_commit(*args, &block)
        set_options_for_callbacks!(args)
        set_callback(:before_commit, :before, *args, &block) # steep:ignore
      end

      def after_commit(*args, &block)
        set_options_for_callbacks!(args, prepend_option)
        set_callback(:commit, :after, *args, &block) # steep:ignore
      end

      def after_rollback(*args, &block)
        set_options_for_callbacks!(args, prepend_option)
        set_callback(:rollback, :after, *args, &block) # steep:ignore
      end

      private

      def ar_class = ActiveRecord::Base

      def prepend_option
        if ActiveRecord.run_after_transaction_callbacks_in_order_defined # steep:ignore
          { prepend: true }
        else
          {}
        end
      end

      def set_options_for_callbacks!(args, enforced_options = {})
        options = args.extract_options!.merge!(enforced_options)
        args << options
      end
    end

    def save(**options) = with_transaction_returning_status { super }

    def save!(**options) = with_transaction_returning_status { super }

    def trigger_transactional_callbacks? = true

    def before_committed!
      _run_before_commit_callbacks
    end

    def committed!(should_run_callbacks: true)
      _run_commit_callbacks if should_run_callbacks
    end

    def rolledback!(force_restore_state: false, should_run_callbacks: true)
      _run_rollback_callbacks if should_run_callbacks
    end

    private

    def with_transaction_returning_status
      with_connection do |connection|
        with_pool_transaction_isolation_level(connection) do
          ensure_finalize = !connection.transaction_open?

          connection.transaction do
            connection.add_transaction_record(self, ensure_finalize || has_transactional_callbacks?) # steep:ignore

            yield.tap { raise ActiveRecord::Rollback unless _1 }
          end
        end
      end
    end

    def with_connection(&block)
      if ActiveRecord.gem_version.release >= Gem::Version.new("7.2.0")
        self.class.with_connection(&block)
      else
        block.call(self.class.connection)
      end
    end

    def with_pool_transaction_isolation_level(connection, &block)
      if ActiveRecord.gem_version.release >= Gem::Version.new("8.1.0")
        isolation_level = ActiveRecord.default_transaction_isolation_level # steep:ignore
        connection.pool.with_pool_transaction_isolation_level(isolation_level, connection.transaction_open?, &block)
      else
        block.call
      end
    end

    def has_transactional_callbacks?
      _rollback_callbacks.present? || _commit_callbacks.present? || _before_commit_callbacks.present? # steep:ignore
    end
  end
end
