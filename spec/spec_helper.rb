# frozen_string_literal: true

require "conexa"
require "webmock/rspec"
require "vcr"
require "byebug"

VCR.configure do |config|
  config.cassette_library_dir = "spec/cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.allow_http_connections_when_no_cassette = true # Bloqueia chamadas sem cassetes
  config.default_cassette_options = { record: :new_episodes }
end


RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include FactoryBot::Syntax::Methods

  config.before(:suite) do
    FactoryBot.find_definitions
  end

  config.before(:each) do
    Conexa.configure do |c|
      c.api_token = "015bce623f2cd6972d9e1d7eda86ff90f0cbc83081e373712d6a7b9445b6432b"
      c.api_host = "https://checkbits.conexa.app"
    end

  end
end
