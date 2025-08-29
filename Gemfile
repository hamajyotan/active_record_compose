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

# model defined in the test is dependent.
gem "bcrypt"

# lint.
gem "rubocop-rails-omakase"
gem "steep", require: false

# document.
gem "yard"
gem "redcarpet"
gem "github-markup"
