# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Conexa::Model do
  # Use Customer as a concrete Model subclass for testing
  let(:model_class) { Conexa::Customer }

  describe '.url' do
    it 'generates pluralized resource URL' do
      expect(model_class.url).to eq('/customers')
    end

    it 'appends additional path segments' do
      expect(model_class.url('123', 'action')).to eq('/customers/123/action')
    end
  end

  describe '.show_url' do
    it 'generates singular resource URL' do
      expect(model_class.show_url).to eq('/customer')
    end

    it 'appends ID to URL' do
      expect(model_class.show_url('123')).to eq('/customer/123')
    end

    it 'appends multiple segments' do
      expect(model_class.show_url('123', 'edit')).to eq('/customer/123/edit')
    end
  end

  describe '.class_name' do
    it 'returns downcased class name without module' do
      expect(model_class.class_name).to eq('customer')
    end
  end

  describe '.underscored_class_name' do
    it 'returns snake_cased class name' do
      expect(model_class.underscored_class_name).to eq('customer')
    end

    it 'handles multi-word names' do
      expect(Conexa::RecurringSale.underscored_class_name).to eq('recurring_sale')
    end
  end

  describe '.extract_page_size_or_params' do
    it 'extracts page and size from positional args' do
      result = model_class.extract_page_size_or_params(2, 50)
      expect(result[:page]).to eq(2)
      expect(result[:size]).to eq(50)
    end

    it 'uses keyword args over positional' do
      result = model_class.extract_page_size_or_params(1, 10, page: 5, size: 100)
      expect(result[:page]).to eq(5)
      expect(result[:size]).to eq(100)
    end

    it 'defaults to page 1, size 100' do
      result = model_class.extract_page_size_or_params
      expect(result[:page]).to eq(1)
      expect(result[:size]).to eq(100)
    end

    it 'preserves additional params' do
      result = model_class.extract_page_size_or_params(status: 'active', companyId: [3])
      expect(result[:status]).to eq('active')
      expect(result[:companyId]).to eq([3])
    end
  end
end
