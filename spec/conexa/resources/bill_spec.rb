# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Conexa::Bill do
  describe 'class methods' do
    describe '.url' do
      it 'returns bills endpoint' do
        expect(described_class.url).to eq('/bills')
      end
    end

    describe '.show_url' do
      it 'returns bill endpoint with id' do
        expect(described_class.show_url(321)).to eq('/bill/321')
      end
    end
  end

  describe 'instance methods' do
    describe '#save' do
      it 'raises NoMethodError (read-only)' do
        bill = described_class.new('id' => 1)
        expect { bill.save }.to raise_error(NoMethodError)
      end
    end
  end

  describe 'inheritance' do
    it 'inherits from Model' do
      expect(described_class).to be < Conexa::Model
    end
  end
end
