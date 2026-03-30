# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Conexa::Account do
  describe 'inheritance' do
    it 'inherits from Model' do
      expect(described_class).to be < Conexa::Model
    end
  end

  describe 'class methods' do
    describe '.url' do
      it 'returns accounts endpoint' do
        expect(described_class.url).to eq('/accounts')
      end
    end

    describe '.show_url' do
      it 'returns account endpoint with id' do
        expect(described_class.show_url(23)).to eq('/account/23')
      end
    end
  end

  describe 'instance' do
    let(:account) { described_class.new('accountId' => 23, 'name' => 'Banco do Brasil') }

    it 'has correct id' do
      expect(account.id).to eq(23)
    end
  end
end
