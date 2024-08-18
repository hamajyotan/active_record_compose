# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in active_record_compose.gemspec
gemspec

case ENV.fetch('AR', 'latest')
when 'latest'
  gem 'activerecord'
  gem 'sqlite3'
when 'head'
  gem 'activerecord', github: 'rails/rails'
  gem 'sqlite3'
else
  gem 'activerecord', ENV.fetch('AR', nil)
  gem 'sqlite3', '~> 1.4'
end

gem 'debug'
gem 'rake'
gem 'rspec'
gem 'rubocop'
gem 'rubocop-rake'
gem 'rubocop-rspec'
gem 'steep', require: false
