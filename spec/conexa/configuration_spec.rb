# spec/conexa/configuration_spec.rb
require 'spec_helper'
require 'conexa'


module Conexa
  RSpec.describe Conexa do
    describe '.configure' do
      it 'yields a configuration object' do
        Conexa.configure do |config|
          expect(config).to be_a(Conexa::Configuration)
        end
      end

      it 'allows setting configuration options' do
        Conexa.configure do |config|
          config.api_token = "TestToken"
          config.api_host = "https://host.conexa.app"
        end

        expect(Conexa.configuration.api_token).to eq("TestToken")
        expect(Conexa.configuration.api_token).to eq("TestToken")
      end
    end

    describe '.api_endpoint' do
      it 'returns the correct API endpoint' do
        Conexa.configure do |config|
          config.api_host = "https://host.conexa.app"
        end


        expect(Conexa.api_endpoint).to eq("https://host.conexa.app/index.php/api/v2")
      end
    end
  end

  RSpec.describe Configuration do
    describe '#initialize' do
      it 'sets default values for configuration attributes' do
        config = Conexa::Configuration.new

        expect(config.api_token).to be_empty
      end
    end

    it 'allows setting and retrieving values for auth_client and auth_token' do
      config = Conexa::Configuration.new
      config.api_token = 'MyAuthToken'

      expect(config.api_token).to eq('MyAuthToken')
    end
  end
end