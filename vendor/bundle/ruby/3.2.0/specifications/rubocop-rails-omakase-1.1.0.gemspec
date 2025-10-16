# -*- encoding: utf-8 -*-
# stub: rubocop-rails-omakase 1.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "rubocop-rails-omakase".freeze
  s.version = "1.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["David Heinemeier Hansson".freeze]
  s.date = "2025-02-25"
  s.email = "david@hey.com".freeze
  s.homepage = "https://github.com/rails/rubocop-rails-omakase".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Omakase Ruby styling for Rails".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<rubocop>.freeze, [">= 1.72"])
  s.add_runtime_dependency(%q<rubocop-rails>.freeze, [">= 2.30"])
  s.add_runtime_dependency(%q<rubocop-performance>.freeze, [">= 1.24"])
end
