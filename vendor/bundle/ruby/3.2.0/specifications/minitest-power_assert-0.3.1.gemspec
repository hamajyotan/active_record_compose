# -*- encoding: utf-8 -*-
# stub: minitest-power_assert 0.3.1 ruby lib

Gem::Specification.new do |s|
  s.name = "minitest-power_assert".freeze
  s.version = "0.3.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["SHIBATA Hiroshi".freeze]
  s.date = "2020-01-30"
  s.description = "Power Assert for Minitest.".freeze
  s.email = ["hsbt@ruby-lang.org".freeze]
  s.homepage = "https://github.com/hsbt/minitest-power_assert".freeze
  s.licenses = ["2-clause BSDL".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Power Assert for Minitest.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<minitest>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<power_assert>.freeze, [">= 1.1"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
end
