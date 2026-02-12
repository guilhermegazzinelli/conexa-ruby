# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Conexa::CreditCard do
  describe 'class methods' do
    describe '.url' do
      it 'returns creditCard endpoint' do
        expect(described_class.url).to eq('/creditCard')
      end
    end

    describe '.show_url' do
      it 'returns creditCard endpoint with id' do
        expect(described_class.show_url(99)).to eq('/creditCard/99')
      end
    end
  end

  describe 'inheritance' do
    it 'inherits from Model' do
      expect(described_class).to be < Conexa::Model
    end
  end
end
