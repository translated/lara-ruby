require_relative 'lib/lara/version'

Gem::Specification.new do |spec|
  spec.name          = "lara-sdk"
  spec.version       = Lara::VERSION
  spec.authors       = ["Translated"]
  spec.email         = ["support@laratranslate.com"]

  spec.summary       = "Official Lara SDK for Ruby"
  spec.description   = "A Ruby library for Lara's API - AI-powered translation services"
  spec.homepage      = "https://laratranslate.com"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/translated/lara-ruby"
  spec.metadata["changelog_uri"] = "https://github.com/translated/lara-ruby/blob/main/CHANGELOG.md"

  spec.files         = Dir["lib/**/*"]
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_dependency "faraday", "~> 1.10"
  spec.add_dependency "faraday-multipart", "~> 1.0"
  spec.add_dependency "mime-types", "~> 3.4"
  spec.add_dependency "multipart-post", ">= 2.3", "< 2.4"

  # Development dependencies
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "simplecov", "~> 0.22"
  spec.add_development_dependency "webmock", "~> 3.18"
  spec.add_development_dependency "yard", "~> 0.9"
end