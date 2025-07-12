# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in active_record_compose.gemspec
gemspec

ar_version = ENV.fetch("AR", "latest")

case ar_version
when "latest"
  gem "activerecord"
  gem "sqlite3", "~> 2.1"
when "head"
  gem "activemodel", github: "rails/rails"
  gem "activerecord", github: "rails/rails"
  gem "activesupport", github: "rails/rails"
  gem "sqlite3", "~> 2.1"
when "~> 7.0.0"
  # HACK: Explicitly load logger for dependency resolution
  # gem activesupport implicitly depends on gem logger.
  # For versions 7.1 or later, this is not a problem since it is listed in add_dependency,
  # but for earlier versions, it is not listed and the dependency needs to be resolved.
  # Also, it seems to be OK to just write the gem 'logger', but it fails when it is required.
  # And the solution with require: false did not work either.
  # This will be resolved after support in 6.1 and 7.0.
  #
  require "logger"

  gem "activerecord", ar_version
  gem "sqlite3", "~> 1.4"
else
  gem "activerecord", ar_version
  gem "sqlite3", "~> 2.1"
end

gem "rake"

# test and debug.
gem "debug"
gem "minitest"
gem "minitest-power_assert"
gem "minitest-reporters"

# lint.
gem "rubocop-rails-omakase"
gem "steep", require: false

# document.
gem "yard"
gem "redcarpet"
gem "github-markup"
