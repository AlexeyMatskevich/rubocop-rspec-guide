# frozen_string_literal: true

require_relative "lib/rubocop/rspec/guide/version"

Gem::Specification.new do |spec|
  spec.name = "rubocop-rspec-guide"
  spec.version = RuboCop::RSpec::Guide::VERSION
  spec.authors = ["Alexey Matskevich"]
  spec.email = ["github_job@mackevich.addymail.com"]

  spec.summary = "Custom RuboCop cops based on the RSpec best practices guide"
  spec.description = "A collection of custom RuboCop cops that enforce best practices from the RSpec style guide, including context structure, testing patterns, and FactoryBot usage."
  spec.homepage = "https://github.com/rspec-guide/rubocop-rspec-guide"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/rspec-guide/rubocop-rspec-guide"
  spec.metadata["changelog_uri"] = "https://github.com/rspec-guide/rubocop-rspec-guide/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.each_line("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "rubocop", "~> 1.50"
  spec.add_dependency "rubocop-rspec", "~> 2.20"

  # Development dependencies
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "standard", "~> 1.24"
  spec.add_development_dependency "benchmark-ips", "~> 2.0"
  spec.add_development_dependency "yard", "~> 0.9"
end
