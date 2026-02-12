# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Conexa::Sale do
  describe 'class methods' do
    describe '.url' do
      it 'returns sales endpoint' do
        expect(described_class.url).to eq('/sales')
      end
    end

    describe '.show_url' do
      it 'returns sale endpoint with id' do
        expect(described_class.show_url(1234)).to eq('/sale/1234')
      end
    end
  end

  describe 'inheritance' do
    it 'inherits from Model' do
      expect(described_class).to be < Conexa::Model
    end
  end
end
