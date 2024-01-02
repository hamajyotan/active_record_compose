# frozen_string_literal: true

require_relative 'lib/active_record_compose/version'

Gem::Specification.new do |spec|
  spec.name = 'active_record_compose'
  spec.version = ActiveRecordCompose::VERSION
  spec.authors = ['hamajyotan']
  spec.email = ['hamajyotan@gmail.com']

  spec.description = 'activemodel form object pattern'
  spec.summary = 'activemodel form object pattern'
  spec.homepage = 'https://github.com/active_record_compose'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.1.0'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end
  spec.require_paths = ['lib']

  spec.add_dependency 'activerecord', '>= 6.1'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.metadata['rubygems_mfa_required'] = 'true'
end
