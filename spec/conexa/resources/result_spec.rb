# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Conexa::Result do
  describe '#empty?' do
    context 'when data is an empty array' do
      let(:result) do
        described_class.new(
          'data' => [],
          'pagination' => {
            'item_per_page' => 100,
            'current_page' => 1,
            'total_pages' => 0,
            'total_items' => 0
          }
        )
      end

      it 'returns true' do
        expect(result.empty?).to be true
      end

      it 'still has pagination info' do
        expect(result.pagination).to be_a(Conexa::Pagination)
        expect(result.pagination.total_items).to eq(0)
      end
    end

    context 'when data has items' do
      let(:result) do
        described_class.new(
          'data' => [{ 'id' => 1, 'name' => 'Customer 1' }],
          'pagination' => {
            'item_per_page' => 100,
            'current_page' => 1,
            'total_pages' => 1,
            'total_items' => 1
          }
        )
      end

      it 'returns false' do
        expect(result.empty?).to be false
      end
    end

    context 'when data is nil' do
      let(:result) do
        described_class.new(
          'pagination' => {
            'item_per_page' => 100,
            'current_page' => 1,
            'total_pages' => 0,
            'total_items' => 0
          }
        )
      end

      it 'returns true' do
        expect(result.empty?).to be true
      end
    end
  end

  describe '#pagination' do
    let(:result) do
      described_class.new(
        'data' => [],
        'pagination' => {
          'item_per_page' => 50,
          'current_page' => 2,
          'total_pages' => 5,
          'total_items' => 250
        }
      )
    end

    it 'returns pagination object' do
      expect(result.pagination).to be_a(Conexa::Pagination)
    end

    it 'has correct pagination values' do
      expect(result.pagination.item_per_page).to eq(50)
      expect(result.pagination.current_page).to eq(2)
      expect(result.pagination.total_pages).to eq(5)
      expect(result.pagination.total_items).to eq(250)
    end
  end
end
