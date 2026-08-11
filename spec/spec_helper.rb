# frozen_string_literal: true

require "conexa"
require "webmock/rspec"
require "vcr"
require "factory_bot"
require "faker"

Dir[File.expand_path("support/**/*.rb", __dir__)].sort.each { |f| require f }

VCR.configure do |config|
  config.cassette_library_dir = "spec/cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.allow_http_connections_when_no_cassette = false # Bloqueia chamadas sem cassetes
  config.default_cassette_options = { record: :new_episodes }

  # Nunca grave o token numa cassette. Uma cassette gravada contra um tenant real
  # já vazou um token de produção neste repositório uma vez; ver
  # claude_scripts/sanitize_cassettes/.
  config.filter_sensitive_data("<API_TOKEN>") { Conexa.configuration&.api_token }
end


RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Without this, `allow(Conexa).to receive(:secret_key)` happily stubs a method
  # that does not exist — which is how the TokenManager specs stayed green over
  # code that raises NoMethodError in any real use.
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.include FactoryBot::Syntax::Methods
  config.include RequestCapture

  config.before(:suite) do
    FactoryBot.find_definitions
  end

  config.before(:each) do
    Conexa.configure do |c|
      c.api_token = "test_token"
      c.api_host = "https://test.conexa.app"
    end
  end
end
