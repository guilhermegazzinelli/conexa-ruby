# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Conexa::CostCenter do
  describe 'inheritance' do
    it 'inherits from Model' do
      expect(described_class).to be < Conexa::Model
    end
  end

  describe 'class methods' do
    describe '.url' do
      it 'returns costCenters endpoint' do
        expect(described_class.url).to eq('/costCenters')
      end
    end

    describe '.show_url' do
      it 'returns costCenter endpoint with id' do
        expect(described_class.show_url(11)).to eq('/costCenter/11')
      end
    end
  end

  describe 'instance' do
    let(:center) { described_class.new('costCenterId' => 11, 'name' => 'Marketing') }

    it 'has correct id' do
      expect(center.id).to eq(11)
    end
  end
end
