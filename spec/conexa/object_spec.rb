# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Conexa::ConexaObject do
  describe '#initialize' do
    it 'creates empty object' do
      obj = described_class.new
      expect(obj.attributes).to eq({})
    end

    it 'initializes with attributes' do
      obj = described_class.new('name' => 'Test', 'value' => 123)
      expect(obj.attributes['name']).to eq('Test')
      expect(obj.attributes['value']).to eq(123)
    end

    it 'converts camelCase to snake_case' do
      obj = described_class.new('firstName' => 'John', 'lastName' => 'Doe')
      expect(obj.attributes['first_name']).to eq('John')
      expect(obj.attributes['last_name']).to eq('Doe')
    end
  end

  describe '#[]=' do
    it 'sets attribute and marks as unsaved' do
      obj = described_class.new
      obj['name'] = 'Test'
      expect(obj.attributes['name']).to eq('Test')
      expect(obj.unsaved_attributes).to include('name' => 'Test')
    end
  end

  describe '#empty?' do
    it 'returns true when no attributes' do
      expect(described_class.new.empty?).to be true
    end

    it 'returns false when has attributes' do
      expect(described_class.new('id' => 1).empty?).to be false
    end
  end

  describe '#==' do
    it 'compares by class and id' do
      obj1 = described_class.new('id' => 1)
      obj2 = described_class.new('id' => 1)
      obj3 = described_class.new('id' => 2)

      expect(obj1).to eq(obj2)
      expect(obj1).not_to eq(obj3)
    end
  end

  describe '#to_hash' do
    it 'converts attributes to hash' do
      obj = described_class.new('name' => 'Test', 'count' => 5)
      hash = obj.to_hash

      expect(hash).to be_a(Hash)
      expect(hash['name']).to eq('Test')
      expect(hash['count']).to eq(5)
    end

    it 'handles nested objects' do
      obj = described_class.new(
        'name' => 'Parent',
        'child' => { 'name' => 'Child' }
      )
      hash = obj.to_hash

      expect(hash['child']).to be_a(Hash)
      expect(hash['child']['name']).to eq('Child')
    end
  end

  describe '#respond_to?' do
    let(:obj) { described_class.new('name' => 'Test') }

    it 'returns true for existing attributes' do
      expect(obj.respond_to?(:name)).to be true
    end

    it 'returns true for setters' do
      expect(obj.respond_to?(:anything=)).to be true
    end

    it 'returns false for non-existent attributes' do
      expect(obj.respond_to?(:nonexistent)).to be false
    end
  end

  describe '#method_missing' do
    let(:obj) { described_class.new('name' => 'Test', 'count' => 5) }

    it 'provides getter for attributes' do
      expect(obj.name).to eq('Test')
      expect(obj.count).to eq(5)
    end

    it 'provides setter for attributes' do
      obj.name = 'New Name'
      expect(obj.name).to eq('New Name')
    end

    it 'delegates array methods to attributes' do
      expect(obj.keys).to include('name', 'count')
    end
  end

  describe '.convert' do
    it 'converts hash to ConexaObject' do
      result = described_class.convert({ 'id' => 1 })
      expect(result).to be_a(Conexa::ConexaObject)
    end

    it 'converts array of hashes' do
      result = described_class.convert([{ 'id' => 1 }, { 'id' => 2 }])
      expect(result).to be_an(Array)
      expect(result.first).to be_a(Conexa::ConexaObject)
    end

    it 'returns primitives as-is' do
      expect(described_class.convert('string')).to eq('string')
      expect(described_class.convert(123)).to eq(123)
      expect(described_class.convert(nil)).to be_nil
    end

    it 'converts to specific resource class when known' do
      result = described_class.convert({ 'customerId' => 1 }, 'customer')
      expect(result).to be_a(Conexa::Customer)
    end
  end

  describe 'RESOURCES' do
    it 'lists all available resources' do
      expect(described_class::RESOURCES).to include(:customer)
      expect(described_class::RESOURCES).to include(:charge)
      expect(described_class::RESOURCES).to include(:contract)
    end
  end
end
