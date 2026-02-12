# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Conexa Errors' do
  describe Conexa::ConexaError do
    it 'inherits from StandardError' do
      expect(Conexa::ConexaError).to be < StandardError
    end
  end

  describe Conexa::ConnectionError do
    let(:original_error) { StandardError.new('Connection refused') }
    let(:error) { described_class.new(original_error) }

    it 'wraps the original error' do
      expect(error.error).to eq(original_error)
    end

    it 'uses original error message' do
      expect(error.message).to eq('Connection refused')
    end
  end

  describe Conexa::RequestError do
    it 'can be raised with a message' do
      expect { raise Conexa::RequestError, 'Invalid ID' }
        .to raise_error(Conexa::RequestError, 'Invalid ID')
    end
  end

  describe Conexa::ResponseError do
    let(:request_params) { { url: '/customer/123', method: :get } }
    let(:original_error) { StandardError.new('Server error') }
    let(:error) { described_class.new(request_params, original_error, 'Additional info') }

    it 'stores request params' do
      expect(error.request_params).to eq(request_params)
    end

    it 'stores original error' do
      expect(error.error).to eq(original_error)
    end

    it 'combines messages' do
      expect(error.message).to eq('Server error => Additional info')
    end
  end

  describe Conexa::NotFound do
    let(:response) { { 'message' => 'Customer not found' } }
    let(:request_params) { { url: '/customer/999' } }
    let(:original_error) { StandardError.new('404') }
    let(:error) { described_class.new(response, request_params, original_error) }

    it 'stores the response' do
      expect(error.response).to eq(response)
    end

    it 'includes message from response' do
      expect(error.message).to include('Customer not found')
    end
  end

  describe Conexa::MissingCredentialsError do
    it 'can be raised' do
      expect { raise Conexa::MissingCredentialsError, 'API token not configured' }
        .to raise_error(Conexa::MissingCredentialsError)
    end
  end

  describe Conexa::ParamError do
    let(:error) do
      described_class.new(
        'Field is required',
        'customer_id',
        'required',
        'https://docs.conexa.com/errors'
      )
    end

    it 'stores parameter details' do
      expect(error.parameter_name).to eq('customer_id')
      expect(error.type).to eq('required')
      expect(error.url).to eq('https://docs.conexa.com/errors')
    end

    it 'converts to hash' do
      expect(error.to_h).to eq({
        parameter_name: 'customer_id',
        type: 'required',
        message: 'Field is required'
      })
    end
  end
end
