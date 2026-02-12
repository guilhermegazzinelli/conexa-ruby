# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Conexa::Model do
  # Create a test class that inherits from Model
  let(:test_class) do
    Class.new(Conexa::Model) do
      def self.name
        'Conexa::TestModel'
      end
    end
  end

  describe '.url' do
    it 'generates pluralized resource URL' do
      expect(test_class.url).to eq('/testmodels')
    end

    it 'appends additional path segments' do
      expect(test_class.url('123', 'action')).to eq('/testmodels/123/action')
    end
  end

  describe '.show_url' do
    it 'generates singular resource URL' do
      expect(test_class.show_url).to eq('/testmodel')
    end

    it 'appends ID to URL' do
      expect(test_class.show_url('123')).to eq('/testmodel/123')
    end

    it 'appends multiple segments' do
      expect(test_class.show_url('123', 'edit')).to eq('/testmodel/123/edit')
    end
  end

  describe '.class_name' do
    it 'returns downcased class name without module' do
      expect(test_class.class_name).to eq('testmodel')
    end
  end

  describe '.underscored_class_name' do
    it 'returns snake_cased class name' do
      expect(test_class.underscored_class_name).to eq('test_model')
    end
  end

  describe '.extract_page_size_or_params' do
    it 'extracts page and size from positional args' do
      result = test_class.extract_page_size_or_params(2, 50)
      expect(result[:page]).to eq(2)
      expect(result[:size]).to eq(50)
    end

    it 'uses keyword args over positional' do
      result = test_class.extract_page_size_or_params(1, 10, page: 5, size: 100)
      expect(result[:page]).to eq(5)
      expect(result[:size]).to eq(100)
    end

    it 'defaults to page 1, size 100' do
      result = test_class.extract_page_size_or_params
      expect(result[:page]).to eq(1)
      expect(result[:size]).to eq(100)
    end

    it 'preserves additional params' do
      result = test_class.extract_page_size_or_params(status: 'active', companyId: [3])
      expect(result[:status]).to eq('active')
      expect(result[:companyId]).to eq([3])
    end
  end

  describe 'instance methods' do
    let(:instance) { test_class.new('testModelId' => 123, 'name' => 'Test') }

    describe '#class_name' do
      it 'returns downcased class name' do
        expect(instance.class_name).to eq('TestModel')
      end
    end

    describe '#primary_key_name' do
      it 'returns id field name based on class' do
        expect(instance.primary_key_name).to eq('testmodel_id')
      end
    end
  end
end
