# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Conexa::Contract do
  describe 'class methods' do
    describe '.url' do
      it 'returns contracts endpoint' do
        expect(described_class.url).to eq('/contracts')
      end
    end

    describe '.show_url' do
      it 'returns contract endpoint with id' do
        expect(described_class.show_url(456)).to eq('/contract/456')
      end

      it 'supports action paths' do
        expect(described_class.show_url('end', 456)).to eq('/contract/end/456')
      end
    end
  end

  describe 'inheritance' do
    it 'inherits from Model' do
      expect(described_class).to be < Conexa::Model
    end
  end

  describe 'instance methods' do
    let(:contract) { described_class.new('contractId' => 456) }

    it 'responds to end_contract' do
      expect(contract).to respond_to(:end_contract)
    end
  end
end
