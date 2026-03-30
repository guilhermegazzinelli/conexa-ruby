# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Conexa::Product do
  describe 'class methods' do
    describe '.url' do
      it 'returns products endpoint' do
        expect(described_class.url).to eq('/products')
      end
    end

    describe '.show_url' do
      it 'returns product endpoint with id' do
        expect(described_class.show_url(100)).to eq('/product/100')
      end
    end
  end

  describe 'inheritance' do
    it 'inherits from Model' do
      expect(described_class).to be < Conexa::Model
    end
  end

  describe 'instance' do
    let(:product) { described_class.new('productId' => 100, 'name' => 'Mensalidade') }

    it 'has correct id' do
      expect(product.id).to eq(100)
    end

    it 'accesses name' do
      expect(product.name).to eq('Mensalidade')
    end
  end
end
