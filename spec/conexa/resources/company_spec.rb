# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Conexa::Company do
  describe 'class methods' do
    describe '.url' do
      # Was asserted as '/companys' — the naive Model#url pluralizer — which is
      # what the API 404s on. The documented path is /companies.
      it 'returns companies endpoint' do
        expect(described_class.url).to eq('/companies')
      end
    end

    describe '.show_url' do
      it 'returns company endpoint with id' do
        expect(described_class.show_url(3)).to eq('/company/3')
      end
    end
  end

  describe 'inheritance' do
    it 'inherits from Model' do
      expect(described_class).to be < Conexa::Model
    end
  end
end
