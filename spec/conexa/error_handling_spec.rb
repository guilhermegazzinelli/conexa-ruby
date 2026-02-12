# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Error Handling for All Resources' do
  let(:api_host) { 'https://checkbits.conexa.app' }
  let(:api_base) { "#{api_host}/index.php/api/v2" }

  around(:each) do |example|
    VCR.turned_off do
      WebMock.enable!
      example.run
    end
  end

  before(:each) do
    Conexa.configure do |c|
      c.api_token = 'test_token'
      c.api_host = api_host
    end
  end

  # List of resources to test - all Model subclasses
  # Use each class's show_url method to get the correct endpoint
  resources = [
    Conexa::Customer,
    Conexa::Company,
    Conexa::Bill,
    Conexa::Charge,
    Conexa::Contract,
    Conexa::CreditCard,
    Conexa::Person,
    Conexa::Plan,
    Conexa::Product,
    Conexa::RecurringSale,
    Conexa::Sale,
    Conexa::Supplier,
  ]

  describe 'NotFound error' do
    resources.each do |resource_class|
      context "for #{resource_class.name.split('::').last}" do
        it 'raises NotFound when ID does not exist' do
          endpoint = resource_class.show_url('nonexistent-id-999')
          stub_request(:get, "#{api_base}#{endpoint}")
            .to_return(
              status: 404,
              body: { message: "#{resource_class.name.split('::').last} not found" }.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )

          expect { resource_class.find('nonexistent-id-999') }
            .to raise_error(Conexa::NotFound) do |error|
              expect(error.response['message']).to include('not found')
            end
        end
      end
    end
  end

  describe 'ResponseError with validation message' do
    resources.each do |resource_class|
      context "for #{resource_class.name.split('::').last}" do
        it 'raises ResponseError when params are invalid' do
          endpoint = resource_class.show_url('invalid-id')
          stub_request(:get, "#{api_base}#{endpoint}")
            .to_return(
              status: 400,
              body: {
                message: 'Invalid parameters',
                errors: [{ field: 'id', message: 'must be a valid UUID' }]
              }.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )

          expect { resource_class.find('invalid-id') }
            .to raise_error(Conexa::ResponseError) do |error|
              expect(error.message).to include('Invalid parameters')
            end
        end
      end
    end
  end

  describe 'ConnectionError when API is offline' do
    resources.each do |resource_class|
      context "for #{resource_class.name.split('::').last}" do
        it 'raises ConnectionError when connection fails' do
          endpoint = resource_class.show_url('some-id')
          stub_request(:get, "#{api_base}#{endpoint}")
            .to_raise(SocketError.new('Connection refused'))

          expect { resource_class.find('some-id') }
            .to raise_error(Conexa::ConnectionError) do |error|
              expect(error.message).to include('Connection refused')
            end
        end
      end
    end
  end

  describe 'ConnectionError when server breaks connection' do
    it 'raises ConnectionError when RestClient::ServerBrokeConnection' do
      stub_request(:get, "#{api_base}/customer/test-id")
        .to_raise(RestClient::ServerBrokeConnection.new('Server broke connection'))

      expect { Conexa::Customer.find('test-id') }
        .to raise_error(Conexa::ConnectionError)
    end
  end

  describe 'NotFound with nil response body' do
    it 'handles 404 without message in body' do
      stub_request(:get, "#{api_base}/customer/missing-id")
        .to_return(
          status: 404,
          body: {}.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { Conexa::Customer.find('missing-id') }
        .to raise_error(Conexa::NotFound) do |error|
          expect(error.response).to be_nil
        end
    end
  end

  describe 'ResponseError with malformed JSON' do
    it 'handles non-JSON error responses' do
      stub_request(:get, "#{api_base}/customer/bad-id")
        .to_return(
          status: 500,
          body: 'Internal Server Error - Not JSON',
          headers: { 'Content-Type' => 'text/plain' }
        )

      expect { Conexa::Customer.find('bad-id') }
        .to raise_error(Conexa::ResponseError)
    end
  end

  describe 'RequestError for invalid operations' do
    it 'raises RequestError when destroying with nil id' do
      customer = Conexa::Customer.new({})

      expect { customer.destroy }
        .to raise_error(Conexa::RequestError, 'Invalid ID')
    end

    it 'raises RequestError when finding with nil id' do
      expect { Conexa::Customer.find(nil) }
        .to raise_error(Conexa::RequestError, 'Invalid ID')
    end

    it 'raises RequestError when finding with empty string id' do
      expect { Conexa::Customer.find('') }
        .to raise_error(Conexa::RequestError, 'Invalid ID')
    end
  end

  describe 'Error inheritance' do
    it 'all custom errors inherit from ConexaError' do
      expect(Conexa::ConnectionError).to be < Conexa::ConexaError
      expect(Conexa::RequestError).to be < Conexa::ConexaError
      expect(Conexa::ResponseError).to be < Conexa::ConexaError
      expect(Conexa::NotFound).to be < Conexa::ResponseError
      expect(Conexa::ValidationError).to be < Conexa::ConexaError
      expect(Conexa::MissingCredentialsError).to be < Conexa::ConexaError
    end
  end
end
