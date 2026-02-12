# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Snake case to camelCase conversion' do
  describe 'Conexa::Util' do
    describe '.camelize_hash' do
      it 'converts snake_case keys to camelCase' do
        input = {
          company_id: 3,
          customer_id: 127,
          is_active: true
        }

        result = Conexa::Util.camelize_hash(input)

        expect(result[:companyId]).to eq(3)
        expect(result[:customerId]).to eq(127)
        expect(result[:isActive]).to eq(true)
      end

      it 'converts nested hash keys' do
        input = {
          legal_person: { cnpj: '123', state_inscription: 'abc' }
        }

        result = Conexa::Util.camelize_hash(input)

        expect(result[:legalPerson]).to be_a(Hash)
        expect(result[:legalPerson][:stateInscription]).to eq('abc')
      end

      it 'preserves non-hash values' do
        input = {
          name: 'Test',
          emails_message: ['a@b.com', 'c@d.com'],
          count: 10
        }

        result = Conexa::Util.camelize_hash(input)

        expect(result[:name]).to eq('Test')
        expect(result[:emailsMessage]).to eq(['a@b.com', 'c@d.com'])
        expect(result[:count]).to eq(10)
      end

      it 'handles nil input' do
        expect(Conexa::Util.camelize_hash(nil)).to eq({})
      end

      it 'handles empty hash' do
        expect(Conexa::Util.camelize_hash({})).to eq({})
      end
    end

    describe '.to_snake_case' do
      it 'converts camelCase to snake_case' do
        expect(Conexa::Util.to_snake_case('customerId')).to eq('customer_id')
        expect(Conexa::Util.to_snake_case('companyId')).to eq('company_id')
        expect(Conexa::Util.to_snake_case('isActive')).to eq('is_active')
        expect(Conexa::Util.to_snake_case('legalPerson')).to eq('legal_person')
        expect(Conexa::Util.to_snake_case('emailsMessage')).to eq('emails_message')
        expect(Conexa::Util.to_snake_case('dueDateFrom')).to eq('due_date_from')
      end

      it 'preserves already snake_case strings' do
        expect(Conexa::Util.to_snake_case('already_snake')).to eq('already_snake')
      end
    end
  end

  describe 'Conexa::ConexaObject' do
    describe 'response attribute access' do
      it 'converts camelCase response to snake_case accessors' do
        customer = Conexa::Customer.new(
          'customerId' => 127,
          'companyId' => 3,
          'isActive' => true,
          'emailsMessage' => ['test@example.com']
        )

        # Access via snake_case
        expect(customer.customer_id).to eq(127)
        expect(customer.company_id).to eq(3)
        expect(customer.is_active).to eq(true)
        expect(customer.emails_message).to eq(['test@example.com'])
      end

      it 'stores attributes with snake_case keys internally' do
        customer = Conexa::Customer.new(
          'customerId' => 127,
          'companyId' => 3
        )

        expect(customer.attributes.keys).to include('customer_id')
        expect(customer.attributes.keys).to include('company_id')
        expect(customer.attributes.keys).not_to include('customerId')
      end

      it 'handles nested objects' do
        customer = Conexa::Customer.new(
          'customerId' => 127,
          'legalPerson' => { 'cnpj' => '12345678000190' }
        )

        expect(customer.legal_person).to be_a(Conexa::ConexaObject)
        expect(customer.legal_person.cnpj).to eq('12345678000190')
      end
    end
  end

  describe 'Conexa::Request' do
    describe '#request_params' do
      it 'converts snake_case POST params to camelCase in payload' do
        request = Conexa::Request.new('/customers', 'POST', params: {
          company_id: 3,
          is_active: true
        })

        params = request.request_params
        payload = MultiJson.decode(params[:payload])

        expect(payload['companyId']).to eq(3)
        expect(payload['isActive']).to eq(true)
      end

      it 'converts snake_case GET params to camelCase in headers' do
        request = Conexa::Request.new('/customers', 'GET', params: {
          company_id: [3],
          is_active: true
        })

        params = request.request_params
        header_params = params[:headers][:params]

        expect(header_params[:companyId]).to eq([3])
        expect(header_params[:isActive]).to eq(true)
      end
    end
  end
end
