# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Conexa::ReceivingMethod do
  describe 'inheritance' do
    it 'inherits from Model' do
      expect(described_class).to be < Conexa::Model
    end
  end

  describe 'class methods' do
    describe '.url' do
      it 'returns receivingMethods endpoint' do
        expect(described_class.url).to eq('/receivingMethods')
      end

      it 'joins additional params with /' do
        expect(described_class.url('active')).to eq('/receivingMethods/active')
      end
    end

    describe '.show_url' do
      it 'returns receivingMethod endpoint (singular)' do
        expect(described_class.show_url).to eq('/receivingMethod')
      end

      it 'returns receivingMethod endpoint with id' do
        expect(described_class.show_url(11)).to eq('/receivingMethod/11')
      end
    end
  end

  describe 'instance' do
    let(:method) { described_class.new('receivingMethodId' => 11, 'name' => 'Cartão de Crédito', 'isActive' => true) }

    it 'accesses attributes via snake_case' do
      expect(method.name).to eq('Cartão de Crédito')
      expect(method.is_active).to be true
    end

    it 'has correct id' do
      expect(method.id).to eq(11)
    end
  end
end
