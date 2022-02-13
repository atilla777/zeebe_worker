# frozen_string_literal: true

require_relative "lib/zeebe_worker/version"

Gem::Specification.new do |spec|
  spec.name = "zeebe_worker"
  spec.version = ZeebeWorker::VERSION
  spec.authors = ["Alexey Slivka"]
  spec.email = ["slivka77@inbox.ru"]

  spec.summary = "Zeebe ruby worker"
  spec.description = "Zeebe ruby worker"
  spec.homepage = "https://github.com/atilla777/zeebe_worker"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "https://github.com"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/atilla777/zeebe_worker"
  spec.metadata["changelog_uri"] = "https://github.com/atilla777/zeebe_worker/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "zeebe-client", "~> 0.16.3"

  spec.add_development_dependency 'rubocop', '~> 1.15.1'
  spec.add_development_dependency 'byebug', '~> 11.1.3'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
