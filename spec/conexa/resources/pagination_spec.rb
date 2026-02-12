# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Conexa::Pagination do
  let(:pagination) do
    described_class.new(
      'item_per_page' => 50,
      'current_page' => 2,
      'total_pages' => 10,
      'total_items' => 500
    )
  end

  describe 'attributes' do
    it 'has item_per_page' do
      expect(pagination.item_per_page).to eq(50)
    end

    it 'has current_page' do
      expect(pagination.current_page).to eq(2)
    end

    it 'has total_pages' do
      expect(pagination.total_pages).to eq(10)
    end

    it 'has total_items' do
      expect(pagination.total_items).to eq(500)
    end
  end

  describe 'inheritance' do
    it 'inherits from ConexaObject' do
      expect(described_class).to be < Conexa::ConexaObject
    end
  end
end
