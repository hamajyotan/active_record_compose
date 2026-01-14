# frozen_string_literal: true

require "active_support/core_ext/module"

module ActiveRecordCompose
  module TransactionSupport
    extend ActiveSupport::Concern

    included do
      define_callbacks :commit, :rollback, :before_commit, scope: [ :kind, :name ]
    end

    # steep:ignore:start

    class_methods do
      # @private
      # @deprecated
      def with_connection(...)
        ActiveRecord.deprecator.warn("`with_connection` is deprecated. Use `ActiveRecord::Base.with_connection` instead.")
        ActiveRecord::Base.with_connection(...)
      end

      # @private
      # @deprecated
      def lease_connection(...)
        ActiveRecord.deprecator.warn("`lease_connection` is deprecated. Use `ActiveRecord::Base.lease_connection` instead.")
        ActiveRecord::Base.lease_connection(...)
      end

      # @private
      # @deprecated
      def connection(...)
        ActiveRecord.deprecator.warn("`connection` is deprecated. Use `ActiveRecord::Base.connection` instead.")
        ActiveRecord::Base.connection(...)
      end
    end

    # steep:ignore:end

    # steep:ignore:start

    class_methods do
      # @private
      def before_commit(*args, &block)
        set_options_for_callbacks!(args)
        set_callback(:before_commit, :before, *args, &block)
      end

      # Registers a block to be called after the transaction is fully committed.
      #
      def after_commit(*args, &block)
        set_options_for_callbacks!(args, prepend_option)
        set_callback(:commit, :after, *args, &block)
      end

      # Registers a block to be called after the transaction is rolled back.
      #
      def after_rollback(*args, &block)
        set_options_for_callbacks!(args, prepend_option)
        set_callback(:rollback, :after, *args, &block)
      end

      private

      # @private
      def prepend_option
        if ActiveRecord.run_after_transaction_callbacks_in_order_defined
          { prepend: true }
        else
          {}
        end
      end

      # @private
      def set_options_for_callbacks!(args, enforced_options = {})
        options = args.extract_options!.merge!(enforced_options)
        args << options
      end
    end

    # steep:ignore:end

    concerning :SupportForActiveRecordConnectionAdaptersTransaction do
      # @private
      def trigger_transactional_callbacks? = true

      # @private
      def before_committed!
        _run_before_commit_callbacks
      end

      # @private
      def committed!(should_run_callbacks: true)
        _run_commit_callbacks if should_run_callbacks
      end

      # @private
      def rolledback!(force_restore_state: false, should_run_callbacks: true)
        _run_rollback_callbacks if should_run_callbacks
      end
    end

    def save(**options) = with_transaction_returning_status { super }

    def save!(**options) = with_transaction_returning_status { super }

    private

    # @private
    def with_transaction_returning_status
      connection_pool.with_connection do |connection|
        with_pool_transaction_isolation_level(connection) do
          ensure_finalize = !connection.transaction_open?

          connection.transaction do
            connection.add_transaction_record(self, ensure_finalize || has_transactional_callbacks?)

            yield.tap { raise ActiveRecord::Rollback unless _1 }
          end || false
        end
      end
    end

    # @private
    def default_ar_class = ActiveRecord::Base

    # @private
    def connection_pool(ar_class: default_ar_class)
      connection_specification_name = ar_class.connection_specification_name
      role = ar_class.current_role
      shard = ar_class.current_shard # steep:ignore
      connection_handler = ar_class.connection_handler # steep:ignore
      retrieve_options = { role:, shard: }
      retrieve_options[:strict] = true if ActiveRecord.gem_version.release >= Gem::Version.new("7.2.0")

      connection_handler.retrieve_connection_pool(connection_specification_name, **retrieve_options)
    end

    # @private
    def with_pool_transaction_isolation_level(connection, &block)
      if ActiveRecord.gem_version.release >= Gem::Version.new("8.1.0")
        isolation_level = ActiveRecord.default_transaction_isolation_level # steep:ignore
        connection.pool.with_pool_transaction_isolation_level(isolation_level, connection.transaction_open?, &block)
      else
        block.call
      end
    end

    # @private
    def has_transactional_callbacks?
      _rollback_callbacks.present? || _commit_callbacks.present? || _before_commit_callbacks.present? # steep:ignore
    end
  end
end
