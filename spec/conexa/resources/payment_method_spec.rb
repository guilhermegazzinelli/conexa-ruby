# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Conexa::PaymentMethod do
  describe 'inheritance' do
    it 'inherits from Model' do
      expect(described_class).to be < Conexa::Model
    end
  end

  describe 'class methods' do
    describe '.url' do
      it 'returns paymentMethods endpoint' do
        expect(described_class.url).to eq('/paymentMethods')
      end
    end

    describe '.show_url' do
      it 'returns paymentMethod endpoint with id' do
        expect(described_class.show_url(2)).to eq('/paymentMethod/2')
      end
    end
  end

  describe 'instance' do
    let(:method) { described_class.new('paymentMethodId' => 2, 'name' => 'Boleto') }

    it 'has correct id' do
      expect(method.id).to eq(2)
    end
  end
end
