# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Conexa::ServiceCategory do
  describe 'inheritance' do
    it 'inherits from Model' do
      expect(described_class).to be < Conexa::Model
    end
  end

  describe 'class methods' do
    describe '.url' do
      it 'returns serviceCategories endpoint' do
        expect(described_class.url).to eq('/serviceCategories')
      end
    end

    describe '.show_url' do
      it 'returns serviceCategory endpoint with id' do
        expect(described_class.show_url(1)).to eq('/serviceCategory/1')
      end
    end
  end

  describe 'instance' do
    let(:category) { described_class.new('serviceCategoryId' => 1, 'name' => 'Consultoria') }

    it 'has correct id' do
      expect(category.id).to eq(1)
    end
  end
end
