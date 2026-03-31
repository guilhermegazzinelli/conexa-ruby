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

    it 'defaults to limit 100, offset 0 (new pagination)' do
      result = model_class.extract_page_size_or_params
      expect(result[:limit]).to eq(100)
      expect(result[:offset]).to eq(0)
      expect(result).not_to have_key(:page)
      expect(result).not_to have_key(:size)
    end

    it 'preserves additional params' do
      result = model_class.extract_page_size_or_params(status: 'active', companyId: [3])
      expect(result[:status]).to eq('active')
      expect(result[:companyId]).to eq([3])
    end

    context 'with limit (new pagination)' do
      it 'uses limit/offset and removes page/size' do
        result = model_class.extract_page_size_or_params(limit: 50)
        expect(result[:limit]).to eq(50)
        expect(result[:offset]).to eq(0)
        expect(result).not_to have_key(:page)
        expect(result).not_to have_key(:size)
      end

      it 'respects custom offset' do
        result = model_class.extract_page_size_or_params(limit: 50, offset: 100)
        expect(result[:limit]).to eq(50)
        expect(result[:offset]).to eq(100)
      end

      it 'preserves filters with limit' do
        result = model_class.extract_page_size_or_params(limit: 20, status: 'active')
        expect(result[:limit]).to eq(20)
        expect(result[:status]).to eq('active')
      end

      it 'raises on non-positive limit' do
        expect { model_class.extract_page_size_or_params(limit: 0) }
          .to raise_error(Conexa::RequestError, /limit must be a positive integer/)
      end

      it 'raises on negative limit' do
        expect { model_class.extract_page_size_or_params(limit: -5) }
          .to raise_error(Conexa::RequestError, /limit must be a positive integer/)
      end

      it 'raises on non-integer limit' do
        expect { model_class.extract_page_size_or_params(limit: 'abc') }
          .to raise_error(Conexa::RequestError, /limit must be a positive integer/)
      end

      it 'raises on negative offset' do
        expect { model_class.extract_page_size_or_params(limit: 10, offset: -1) }
          .to raise_error(Conexa::RequestError, /offset must be a non-negative integer/)
      end
    end
  end

  describe '.class_name' do
    it 'returns lowerCamelCase for compound names' do
      expect(Conexa::RecurringSale.class_name).to eq('recurringSale')
    end

    it 'returns lowercase for simple names' do
      expect(model_class.class_name).to eq('customer')
    end
  end
end
