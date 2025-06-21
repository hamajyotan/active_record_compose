# frozen_string_literal: true

require_relative 'lib/active_record_compose/version'

Gem::Specification.new do |spec|
  spec.name = 'active_record_compose'
  spec.version = ActiveRecordCompose::VERSION
  spec.authors = [ 'hamajyotan' ]
  spec.email = [ 'hamajyotan@gmail.com' ]

  spec.description = 'activemodel form object pattern. ' \
                     'it embraces multiple AR models and provides ' \
                     'a transparent interface as if they were a single model.'
  spec.summary = 'activemodel form object pattern'
  spec.homepage = 'https://github.com/hamajyotan/active_record_compose'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.1.0'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[
                        bin/
                        test/
                        spec/
                        features/
                        .git
                        .circleci
                        appveyor
                        Gemfile
                        Rakefile
                        rbs_collection.yaml
                        Steepfile
                      ])
    end
  end
  spec.require_paths = [ 'lib' ]

  spec.add_dependency 'activerecord', '>= 7.0', '< 8.1'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['documentation_uri'] = "https://www.rubydoc.info/gems/active_record_compose/#{spec.version}"
  spec.metadata['rubygems_mfa_required'] = 'true'
end
