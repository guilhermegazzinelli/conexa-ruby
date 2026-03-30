# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Conexa::Supplier do
  describe 'inheritance' do
    it 'inherits from Model' do
      expect(described_class).to be < Conexa::Model
    end
  end

  describe 'class methods' do
    describe '.url' do
      it 'returns suppliers endpoint (plural)' do
        expect(described_class.url).to eq('/suppliers')
      end
    end

    describe '.show_url' do
      it 'returns supplier endpoint with id' do
        expect(described_class.show_url(50)).to eq('/supplier/50')
      end
    end
  end

  describe 'instance' do
    let(:supplier) { described_class.new('supplierId' => 50, 'name' => 'Fornecedor ABC') }

    it 'has correct id' do
      expect(supplier.id).to eq(50)
    end
  end
end
