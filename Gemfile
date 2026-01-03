# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in active_record_compose.gemspec
gemspec

ar_version = ENV.fetch("AR", "latest")

case ar_version
when "latest"
  gem "activerecord"
  gem "railties"
when "head"
  gem "activemodel", github: "rails/rails"
  gem "activerecord", github: "rails/rails"
  gem "activesupport", github: "rails/rails"
  gem "railties", github: "rails/rails"
when /-stable\z/
  gem "activemodel", github: "rails/rails", branch: ar_version
  gem "activerecord", github: "rails/rails", branch: ar_version
  gem "activesupport", github: "rails/rails", branch: ar_version
  gem "railties", github: "rails/rails", branch: ar_version
else
  gem "activerecord", ar_version
  gem "railties", ar_version
end

gem "sqlite3", "~> 2.1"

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
gem "yard", "0.9.37" # TODO: Side navigation links don't work in 0.9.38, so I'm working around it.
gem "yard-activesupport-concern"
gem "webrick"
gem "redcarpet"
gem "github-markup"
