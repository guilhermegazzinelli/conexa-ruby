# frozen_string_literal: true

require_relative "lib/conexa/version"


Gem::Specification.new do |spec|
  spec.name = "conexa"
  spec.version = Conexa::VERSION
  spec.authors = ["Guilherme Gazzinelli"]
  spec.email = ["guilherme.gazzinelli@gmail.com"]
  spec.licenses  = ['MIT']

  spec.summary = "Gem para integração com a Api da Conexa"
  spec.description = "Gem para integração com a Conexa"
  spec.homepage = "https://github.com/guilhermegazzinelli/conexa-ruby"

  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/guilhermegazzinelli/conexa-ruby"
  spec.metadata["changelog_uri"] = "https://github.com/guilhermegazzinelli/conexa-ruby/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "jwt"
  spec.add_dependency "rest-client"
  spec.add_dependency "multi_json"

  spec.add_development_dependency 'vcr'
  spec.add_development_dependency 'webmock'
  spec.add_development_dependency 'debug'
  spec.add_development_dependency 'faker'
  spec.add_development_dependency 'factory_bot'



end
