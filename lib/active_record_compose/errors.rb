# frozen_string_literal: true

module ActiveRecordCompose
  class Error < StandardError
  end

  class LockedCollectionError < Error
    def initialize(cause, owner)
      super(cause)
      @owner = owner
    end

    attr_reader :owner
  end
end
