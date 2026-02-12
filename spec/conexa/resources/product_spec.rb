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

  describe 'instance methods' do
    describe '#save' do
      it 'raises NoMethodError (read-only)' do
        product = described_class.new('id' => 1)
        expect { product.save }.to raise_error(NoMethodError)
      end
    end
  end

  describe 'inheritance' do
    it 'inherits from Model' do
      expect(described_class).to be < Conexa::Model
    end
  end
end
