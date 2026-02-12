# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Conexa::Supplier do
  describe 'class methods' do
    describe '.url' do
      it 'returns supplier endpoint (singular)' do
        expect(described_class.url).to eq('/supplier')
      end
    end

    describe '.show_url' do
      it 'returns supplier endpoint with id' do
        expect(described_class.show_url(50)).to eq('/supplier/50')
      end
    end
  end

  describe 'inheritance' do
    it 'inherits from Model' do
      expect(described_class).to be < Conexa::Model
    end
  end
end
