# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Conexa::Customer do
  describe 'class methods' do
    describe '.url' do
      it 'returns customers endpoint' do
        expect(described_class.url).to eq('/customers')
      end
    end

    describe '.show_url' do
      it 'returns customer endpoint with id' do
        expect(described_class.show_url(127)).to eq('/customer/127')
      end
    end

    describe '.persons' do
      it 'is defined' do
        expect(described_class).to respond_to(:persons)
      end
    end

    describe '.contracts' do
      it 'is defined' do
        expect(described_class).to respond_to(:contracts)
      end
    end

    describe '.charges' do
      it 'is defined' do
        expect(described_class).to respond_to(:charges)
      end
    end
  end

  describe 'inheritance' do
    it 'inherits from Model' do
      expect(described_class).to be < Conexa::Model
    end
  end

  describe 'instance methods' do
    let(:customer) do
      described_class.new(
        'customerId' => 127,
        'name' => 'Test Customer',
        'companyId' => 3
      )
    end

    it 'has customerId' do
      expect(customer.customer_id).to eq(127)
    end

    it 'has name' do
      expect(customer.name).to eq('Test Customer')
    end

    it 'has companyId' do
      expect(customer.company_id).to eq(3)
    end
  end
end
