# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Conexa::Person do
  describe 'class methods' do
    describe '.url' do
      it 'returns /persons' do
        expect(described_class.url).to eq('/persons')
      end
    end

    describe '.show_url' do
      it 'returns /person' do
        expect(described_class.show_url).to eq('/person')
      end

      it 'returns /person/:id' do
        expect(described_class.show_url(458)).to eq('/person/458')
      end
    end
  end

  describe 'inheritance' do
    it 'inherits from Model' do
      expect(described_class).to be < Conexa::Model
    end
  end
end
