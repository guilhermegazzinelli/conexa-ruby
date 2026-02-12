# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Nil Guards' do
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

  describe 'Util.camelize_hash with nil' do
    it 'returns empty hash when given nil' do
      result = Conexa::Util.camelize_hash(nil)
      expect(result).to eq({})
    end

    it 'handles empty hash' do
      result = Conexa::Util.camelize_hash({})
      expect(result).to eq({})
    end

    it 'handles hash with nil values' do
      result = Conexa::Util.camelize_hash({ name: nil, age: 25 })
      expect(result).to eq({ name: nil, age: 25 })
    end

    it 'handles nested hash with nil values' do
      result = Conexa::Util.camelize_hash({
        customer_name: 'John',
        address_info: {
          street_name: nil,
          city_name: 'NYC'
        }
      })
      expect(result[:customerName]).to eq('John')
      expect(result[:addressInfo][:streetName]).to be_nil
      expect(result[:addressInfo][:cityName]).to eq('NYC')
    end
  end

  describe 'Result#empty? with data: nil' do
    it 'returns true when data is nil' do
      result = Conexa::Result.new({ 'data' => nil, 'pagination' => {} })
      expect(result.empty?).to be true
    end

    it 'returns true when data is empty array' do
      result = Conexa::Result.new({ 'data' => [], 'pagination' => {} })
      expect(result.empty?).to be true
    end

    it 'returns false when data has items' do
      result = Conexa::Result.new({ 'data' => [{ 'id' => 1 }], 'pagination' => {} })
      expect(result.empty?).to be false
    end

    it 'handles Result with only pagination (no data key)' do
      result = Conexa::Result.new({ 'pagination' => { 'page' => 1 } })
      expect(result.empty?).to be true
    end
  end

  describe 'Model#find with nil ID' do
    it 'raises RequestError when ID is nil' do
      expect { Conexa::Customer.find(nil) }
        .to raise_error(Conexa::RequestError, 'Invalid ID')
    end

    it 'raises RequestError when ID is empty string' do
      expect { Conexa::Customer.find('') }
        .to raise_error(Conexa::RequestError, 'Invalid ID')
    end

    # Note: whitespace-only strings are considered present in this gem's implementation
    # so they won't trigger RequestError. However, the gem doesn't URL-encode the ID,
    # which causes URI::InvalidURIError when spaces are passed.
    it 'raises URI error for whitespace ID (no URL encoding)' do
      expect { Conexa::Customer.find('   ') }
        .to raise_error(URI::InvalidURIError)
    end

    it 'does not raise for valid ID (mocked)' do
      stub_request(:get, "#{api_base}/customer/valid-id-123")
        .to_return(
          status: 200,
          body: { id: 'valid-id-123', name: 'Test' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = Conexa::Customer.find('valid-id-123')
      expect(result.id).to eq('valid-id-123')
    end
  end

  describe 'Model#find_by_id alias' do
    it 'raises RequestError when ID is nil' do
      expect { Conexa::Customer.find_by_id(nil) }
        .to raise_error(Conexa::RequestError, 'Invalid ID')
    end

    it 'raises RequestError when ID is empty' do
      expect { Conexa::Customer.find_by_id('') }
        .to raise_error(Conexa::RequestError, 'Invalid ID')
    end
  end

  describe 'Model#destroy with nil ID' do
    it 'raises RequestError when instance has no ID' do
      customer = Conexa::Customer.new({})
      expect { customer.destroy }
        .to raise_error(Conexa::RequestError, 'Invalid ID')
    end

    it 'raises RequestError when instance ID is nil' do
      customer = Conexa::Customer.new({ 'id' => nil })
      expect { customer.destroy }
        .to raise_error(Conexa::RequestError, 'Invalid ID')
    end
  end

  describe 'ConexaObject with nil attributes' do
    it 'handles initialization with nil by raising NoMethodError' do
      # ConexaObject.new expects a hash; nil.to_hash and nil.each will fail
      # This documents the current behavior - nil is not a valid input
      expect { Conexa::ConexaObject.new(nil) }.to raise_error(NoMethodError)
    end

    it 'handles initialization with empty hash' do
      obj = Conexa::ConexaObject.new({})
      expect(obj.attributes).to eq({})
      expect(obj.empty?).to be true
    end

    it 'handles attribute access for non-existent keys' do
      obj = Conexa::ConexaObject.new({ 'name' => 'Test' })
      expect(obj.nonexistent_key).to be_nil
    end

    it 'handles nested nil values' do
      obj = Conexa::ConexaObject.new({
        'name' => 'Test',
        'address' => nil,
        'details' => { 'info' => nil }
      })
      expect(obj.name).to eq('Test')
      expect(obj.address).to be_nil
      expect(obj.details.info).to be_nil
    end
  end

  describe 'Response conversion with nil' do
    it 'handles ConexaObject.convert with nil' do
      result = Conexa::ConexaObject.convert(nil, 'customer')
      expect(result).to be_nil
    end

    it 'handles ConexaObject.convert with empty array' do
      result = Conexa::ConexaObject.convert([], 'customer')
      expect(result).to eq([])
    end

    it 'handles ConexaObject.convert with empty hash' do
      result = Conexa::ConexaObject.convert({}, 'customer')
      expect(result).to be_a(Conexa::Customer)
      expect(result.empty?).to be true
    end
  end

  describe 'Util edge cases' do
    describe '.to_snake_case' do
      it 'handles nil gracefully via to_s' do
        # nil.to_s returns "", gsub on "" works fine
        expect { Conexa::Util.to_snake_case(nil.to_s) }.not_to raise_error
        expect(Conexa::Util.to_snake_case('')).to eq('')
      end

      it 'handles empty string' do
        expect(Conexa::Util.to_snake_case('')).to eq('')
      end
    end

    describe '.singularize' do
      it 'handles empty string' do
        expect(Conexa::Util.singularize('')).to eq('')
      end

      it 'handles nil via to_s' do
        expect { Conexa::Util.singularize(nil) }.not_to raise_error
      end
    end

    describe '.camel_case_lower' do
      it 'handles empty string' do
        expect(Conexa::Util.camel_case_lower('')).to eq('')
      end

      it 'handles nil via to_s' do
        expect(Conexa::Util.camel_case_lower(nil)).to eq('')
      end
    end
  end

  describe 'Request with nil parameters' do
    it 'handles nil params in camelize_hash' do
      request = Conexa::Request.new('/test', 'GET', params: nil)
      # request_params calls Util.camelize_hash(@parameters)
      expect { request.request_params }.not_to raise_error
    end
  end

  describe 'Model.all with nil filters' do
    it 'handles nil in filter hash values' do
      stub_request(:get, "#{api_base}/customers")
        .with(query: hash_including({ 'page' => '1', 'size' => '100' }))
        .to_return(
          status: 200,
          body: { data: [], pagination: { page: 1, size: 100, totalPages: 0, totalElements: 0 } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = Conexa::Customer.all(page: 1, size: 100, status: nil)
      expect(result).to be_a(Conexa::Result)
    end
  end

  describe 'unsaved_attributes with nil values' do
    it 'handles setting nil values' do
      obj = Conexa::ConexaObject.new({ 'name' => 'Test' })
      obj['status'] = nil

      expect(obj.unsaved_attributes).to eq({ 'status' => nil })
    end
  end

  describe 'to_hash with nil values' do
    it 'preserves nil values in to_hash' do
      obj = Conexa::ConexaObject.new({ 'name' => 'Test', 'email' => nil })
      hash = obj.to_hash

      expect(hash['name']).to eq('Test')
      expect(hash['email']).to be_nil
      expect(hash.key?('email')).to be true
    end
  end
end
