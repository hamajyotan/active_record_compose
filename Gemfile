# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in active_record_compose.gemspec
gemspec

ar_version = ENV.fetch('AR', 'latest')

case ar_version
when 'latest'
  gem 'activerecord'
  gem 'sqlite3', '~> 2.1'
when 'head'
  gem 'activerecord', github: 'rails/rails'
  gem 'sqlite3', '~> 2.1'
when '~> 8.0.0'
  gem 'activerecord', ar_version
  gem 'sqlite3', '~> 2.1'
else
  gem 'activerecord', ar_version
  gem 'sqlite3', '~> 1.4'
end

gem 'activesupport'
gem 'debug'
gem 'minitest'
gem 'rake'
gem 'rubocop'
gem 'rubocop-minitest'
gem 'rubocop-rake'
gem 'steep', require: false
