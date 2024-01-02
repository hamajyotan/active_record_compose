# frozen_string_literal: true

module ActiveRecordCompose
  class Error < ::StandardError; end

  class RecordNotSaved < ::ActiveRecordCompose::Error
    def initialize(message, record)
      super(message)
      @record = record
    end

    attr_reader :record
  end
end
