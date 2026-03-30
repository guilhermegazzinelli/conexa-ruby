# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Conexa::BillSubcategory do
  describe 'inheritance' do
    it 'inherits from Model' do
      expect(described_class).to be < Conexa::Model
    end
  end

  describe 'class methods' do
    describe '.url' do
      it 'returns billSubcategories endpoint' do
        expect(described_class.url).to eq('/billSubcategories')
      end
    end

    describe '.show_url' do
      it 'returns billSubcategory endpoint with id' do
        expect(described_class.show_url(29)).to eq('/billSubcategory/29')
      end
    end
  end

  describe 'instance' do
    let(:subcategory) { described_class.new('billSubcategoryId' => 29, 'name' => 'Taxa de Cartão', 'billCategoryId' => 4) }

    it 'has correct id' do
      expect(subcategory.id).to eq(29)
    end

    it 'accesses parent category id' do
      expect(subcategory.bill_category_id).to eq(4)
    end
  end
end
