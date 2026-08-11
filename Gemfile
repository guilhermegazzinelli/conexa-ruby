# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in conexa.gemspec.
# The gemspec's development dependencies land in :test (not :development) so the
# suite can be installed and run without the optional REPL tooling below.
gemspec development_group: :test

gem "rake", "~> 13.0"

gem "rspec", "~> 3.0"

gem "rubocop", "~> 1.21"

gem "standard"

group :development do
  # Optional REPL/debugger tooling. Skip with `bundle install --without development`
  # if the io-console native extension will not build on your ruby.
  gem "debug"
  gem "byebug"
end

