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

  # Matches the CI matrix. Everything below 3.1 is EOL, and the suite has never
  # been run against it.
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/guilhermegazzinelli/conexa-ruby"
  spec.metadata["changelog_uri"] = "https://github.com/guilhermegazzinelli/conexa-ruby/blob/main/CHANGELOG.md"

  # Ship only what a consumer of the gem needs.
  #
  # The default `git ls-files` minus a few dotfiles used to package everything in
  # the repo: docs/postman-collection.json alone is 1.7 MB against 58 KB of
  # library code, plus the .okf knowledge bundle and the dev scripts. Those belong
  # in the repository, not in every install.
  packaged = %r{\A(?:lib/|(?:README(?:_pt-BR)?|REFERENCE|CHANGELOG|CODE_OF_CONDUCT)\.md\z|LICENSE\z)}

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").grep(packaged)
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rest-client", "~> 2.1"
  # multi_json's adapter behaviour is load-bearing: with Oj, decoding an empty
  # body returns nil rather than raising, which Request#run has to guard for.
  spec.add_dependency "multi_json", "~> 1.15"

  # Only what the suite itself needs. REPL/debugger tooling lives in the Gemfile's
  # :development group — `debug` pulls irb -> reline -> io-console, whose native
  # extension fails to build on some ruby/gcc combinations and would otherwise
  # block a contributor from running the specs at all.
  spec.add_development_dependency 'vcr', '~> 6.0'
  spec.add_development_dependency 'webmock', '~> 3.0'
  spec.add_development_dependency 'faker', '~> 3.0'
  spec.add_development_dependency 'factory_bot', '~> 6.0'



end
