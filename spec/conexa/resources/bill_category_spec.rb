# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Conexa::BillCategory do
  describe 'inheritance' do
    it 'inherits from Model' do
      expect(described_class).to be < Conexa::Model
    end
  end

  describe 'class methods' do
    describe '.url' do
      it 'returns billCategories endpoint' do
        expect(described_class.url).to eq('/billCategories')
      end
    end

    describe '.show_url' do
      it 'returns billCategory endpoint with id' do
        expect(described_class.show_url(4)).to eq('/billCategory/4')
      end
    end
  end

  describe 'instance' do
    let(:category) { described_class.new('billCategoryId' => 4, 'name' => 'Impostos') }

    it 'has correct id' do
      expect(category.id).to eq(4)
    end
  end
end
