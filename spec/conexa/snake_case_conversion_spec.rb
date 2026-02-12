# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Snake case to camelCase conversion' do
  describe 'Conexa::Request' do
    describe '#request_params' do
      it 'converts snake_case parameters to camelCase' do
        request = Conexa::Request.new('/customers', 'POST', params: {
          company_id: 3,
          legal_person: { cnpj: '99.557.155/0001-90' },
          emails_message: ['test@example.com'],
          is_active: true
        })

        params = request.request_params
        payload = MultiJson.decode(params[:payload])

        expect(payload['companyId']).to eq(3)
        expect(payload['legalPerson']).to eq({ 'cnpj' => '99.557.155/0001-90' })
        expect(payload['emailsMessage']).to eq(['test@example.com'])
        expect(payload['isActive']).to eq(true)
      end

      it 'handles nested snake_case keys' do
        request = Conexa::Request.new('/contracts', 'POST', params: {
          customer_id: 127,
          start_date: '2024-01-01',
          payment_day: 10,
          items: [
            { product_id: 100, unit_price: 99.90 }
          ]
        })

        params = request.request_params
        payload = MultiJson.decode(params[:payload])

        expect(payload['customerId']).to eq(127)
        expect(payload['startDate']).to eq('2024-01-01')
        expect(payload['paymentDay']).to eq(10)
        expect(payload['items'].first['productId']).to eq(100)
        expect(payload['items'].first['unitPrice']).to eq(99.90)
      end

      it 'converts GET params to camelCase' do
        request = Conexa::Request.new('/customers', 'GET', params: {
          company_id: [3],
          is_active: true,
          page: 1,
          size: 50
        })

        params = request.request_params
        header_params = params[:headers][:params]

        expect(header_params[:companyId]).to eq([3])
        expect(header_params[:isActive]).to eq(true)
        expect(header_params[:page]).to eq(1)
        expect(header_params[:size]).to eq(50)
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
          'legalPerson' => { 'cnpj' => '99.557.155/0001-90' },
          'emailsMessage' => ['test@example.com']
        )

        # Access via snake_case
        expect(customer.customer_id).to eq(127)
        expect(customer.company_id).to eq(3)
        expect(customer.is_active).to eq(true)
        expect(customer.legal_person).to be_a(Conexa::ConexaObject)
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
    end
  end

  describe 'Conexa::Util' do
    describe '.camelize_hash' do
      it 'converts all common snake_case patterns' do
        input = {
          company_id: 3,
          customer_id: 127,
          is_active: true,
          legal_person: { cnpj: '123' },
          emails_message: ['a@b.com'],
          start_date: '2024-01-01',
          payment_day: 10,
          due_date_from: '2024-01-01',
          due_date_to: '2024-01-31'
        }

        result = Conexa::Util.camelize_hash(input)

        expect(result[:companyId]).to eq(3)
        expect(result[:customerId]).to eq(127)
        expect(result[:isActive]).to eq(true)
        expect(result[:legalPerson]).to eq({ cnpj: '123' })
        expect(result[:emailsMessage]).to eq(['a@b.com'])
        expect(result[:startDate]).to eq('2024-01-01')
        expect(result[:paymentDay]).to eq(10)
        expect(result[:dueDateFrom]).to eq('2024-01-01')
        expect(result[:dueDateTo]).to eq('2024-01-31')
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
    end
  end
end
