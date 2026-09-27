# frozen_string_literal: true

module ActiveRecordCompose
  VERSION = "1.3.0"

  class << self
    def version = Gem::Version.new(VERSION)

    private

    # @private
    def next_major_version
      version.segments.first + 1 # steep:ignore
    end
  end
end
