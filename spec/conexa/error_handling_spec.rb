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
  resources = {
    'Customer' => { class: Conexa::Customer, endpoint: '/customer' },
    'Company' => { class: Conexa::Company, endpoint: '/company' },
    'Bill' => { class: Conexa::Bill, endpoint: '/bill' },
    'Charge' => { class: Conexa::Charge, endpoint: '/charge' },
    'Contract' => { class: Conexa::Contract, endpoint: '/contract' },
    'CreditCard' => { class: Conexa::CreditCard, endpoint: '/creditcard' },
    'LegalPerson' => { class: Conexa::LegalPerson, endpoint: '/legalperson' },
    'Person' => { class: Conexa::Person, endpoint: '/person' },
    'Plan' => { class: Conexa::Plan, endpoint: '/plan' },
    'Product' => { class: Conexa::Product, endpoint: '/product' },
    'RecurringSale' => { class: Conexa::RecurringSale, endpoint: '/recurringsale' },
    'Sale' => { class: Conexa::Sale, endpoint: '/sale' },
    'Supplier' => { class: Conexa::Supplier, endpoint: '/supplier' },
  }

  describe 'NotFound error' do
    resources.each do |name, config|
      context "for #{name}" do
        it 'raises NotFound when ID does not exist' do
          stub_request(:get, "#{api_base}#{config[:endpoint]}/nonexistent-id-999")
            .to_return(
              status: 404,
              body: { message: "#{name} not found" }.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )

          expect { config[:class].find('nonexistent-id-999') }
            .to raise_error(Conexa::NotFound) do |error|
              expect(error.response['message']).to eq("#{name} not found")
            end
        end
      end
    end
  end

  describe 'ResponseError with validation message' do
    resources.each do |name, config|
      context "for #{name}" do
        it 'raises ResponseError when params are invalid' do
          stub_request(:get, "#{api_base}#{config[:endpoint]}/invalid-id")
            .to_return(
              status: 400,
              body: {
                message: 'Invalid parameters',
                errors: [{ field: 'id', message: 'must be a valid UUID' }]
              }.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )

          expect { config[:class].find('invalid-id') }
            .to raise_error(Conexa::ResponseError) do |error|
              expect(error.message).to include('Invalid parameters')
            end
        end
      end
    end
  end

  describe 'ConnectionError when API is offline' do
    resources.each do |name, config|
      context "for #{name}" do
        it 'raises ConnectionError when connection fails' do
          stub_request(:get, "#{api_base}#{config[:endpoint]}/some-id")
            .to_raise(SocketError.new('Connection refused'))

          expect { config[:class].find('some-id') }
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
