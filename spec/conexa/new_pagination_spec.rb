# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'New Pagination (limit/offset/hasNext)' do
  let(:api_host) { 'https://checkbits.conexa.app' }
  let(:api_base) { "#{api_host}/index.php/api/v2" }

  around(:each) do |example|
    VCR.turned_off do
      WebMock.enable!
      example.run
    end
  end

  before(:each) do
    Conexa.configure do |c|
      c.api_token = 'test_token'
      c.api_host = api_host
    end
  end

  describe 'extract_page_size_or_params with limit' do
    it 'uses limit/offset when limit is present' do
      result = Conexa::Customer.send(:extract_page_size_or_params, limit: 50)
      expect(result[:limit]).to eq(50)
      expect(result[:offset]).to eq(0)
      expect(result).not_to have_key(:page)
      expect(result).not_to have_key(:size)
    end

    it 'uses limit/offset with custom offset' do
      result = Conexa::Customer.send(:extract_page_size_or_params, limit: 50, offset: 100)
      expect(result[:limit]).to eq(50)
      expect(result[:offset]).to eq(100)
    end

    it 'preserves filter params with limit' do
      result = Conexa::Customer.send(:extract_page_size_or_params, limit: 20, status: 'active', company_id: [3])
      expect(result[:limit]).to eq(20)
      expect(result[:offset]).to eq(0)
      expect(result[:status]).to eq('active')
      expect(result[:company_id]).to eq([3])
    end

    it 'strips page/size when limit is used' do
      result = Conexa::Customer.send(:extract_page_size_or_params, limit: 20, page: 5, size: 100)
      expect(result[:limit]).to eq(20)
      expect(result).not_to have_key(:page)
      expect(result).not_to have_key(:size)
    end
  end

  describe 'deprecation warning for legacy pagination' do
    it 'warns when using page/size' do
      expect { Conexa::Customer.send(:extract_page_size_or_params, page: 1, size: 50) }
        .to output(/DEPRECATION WARNING/).to_stderr
    end

    it 'does not warn when using limit' do
      expect { Conexa::Customer.send(:extract_page_size_or_params, limit: 50) }
        .not_to output.to_stderr
    end
  end

  describe 'skip page/size validation for limit mode' do
    it 'does not raise for limit-only calls' do
      stub_request(:get, "#{api_base}/customers")
        .with(query: hash_including({ 'limit' => '50', 'offset' => '0' }))
        .to_return(
          status: 200,
          body: {
            data: [],
            pagination: { limit: 50, offset: 0, hasNext: false }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { Conexa::Customer.all(limit: 50) }.not_to raise_error
    end
  end

  describe 'API response with new pagination' do
    it 'parses hasNext in pagination' do
      stub_request(:get, "#{api_base}/customers")
        .with(query: hash_including({ 'limit' => '10', 'offset' => '0' }))
        .to_return(
          status: 200,
          body: {
            data: [{ customerId: 1, name: 'Customer 1' }, { customerId: 2, name: 'Customer 2' }],
            pagination: { limit: 10, offset: 0, hasNext: true }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = Conexa::Customer.all(limit: 10)

      expect(result).to be_a(Conexa::Result)
      expect(result.data.size).to eq(2)
      expect(result.pagination.limit).to eq(10)
      expect(result.pagination.offset).to eq(0)
      expect(result.pagination.has_next).to be true
    end

    it 'handles hasNext false (last page)' do
      stub_request(:get, "#{api_base}/customers")
        .with(query: hash_including({ 'limit' => '10', 'offset' => '20' }))
        .to_return(
          status: 200,
          body: {
            data: [{ customerId: 3, name: 'Customer 3' }],
            pagination: { limit: 10, offset: 20, hasNext: false }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = Conexa::Customer.all(limit: 10, offset: 20)

      expect(result.pagination.has_next).to be false
    end

    it 'handles empty response with new pagination' do
      stub_request(:get, "#{api_base}/customers")
        .with(query: hash_including({ 'limit' => '10', 'offset' => '0' }))
        .to_return(
          status: 200,
          body: {
            data: [],
            pagination: { limit: 10, offset: 0, hasNext: false }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = Conexa::Customer.all(limit: 10)

      expect(result.empty?).to be true
      expect(result.pagination.has_next).to be false
    end
  end

  describe 'default pagination (no params)' do
    it 'defaults to limit/offset instead of page/size' do
      result = Conexa::Customer.send(:extract_page_size_or_params)
      expect(result[:limit]).to eq(100)
      expect(result[:offset]).to eq(0)
      expect(result).not_to have_key(:page)
      expect(result).not_to have_key(:size)
    end

    it 'does not emit deprecation warning' do
      expect { Conexa::Customer.send(:extract_page_size_or_params) }
        .not_to output.to_stderr
    end
  end

  describe '#has_next?' do
    it 'returns true when has_next is true' do
      stub_request(:get, "#{api_base}/customers")
        .with(query: hash_including({ 'limit' => '10', 'offset' => '0' }))
        .to_return(
          status: 200,
          body: {
            data: [{ customerId: 1, name: 'Customer 1' }],
            pagination: { limit: 10, offset: 0, hasNext: true }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = Conexa::Customer.all(limit: 10)
      expect(result.has_next?).to be true
    end

    it 'returns false when has_next is false' do
      stub_request(:get, "#{api_base}/customers")
        .with(query: hash_including({ 'limit' => '10', 'offset' => '0' }))
        .to_return(
          status: 200,
          body: {
            data: [],
            pagination: { limit: 10, offset: 0, hasNext: false }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = Conexa::Customer.all(limit: 10)
      expect(result.has_next?).to be false
    end
  end

  describe '#next_page' do
    it 'fetches the next page with correct offset' do
      stub_request(:get, "#{api_base}/customers")
        .with(query: hash_including({ 'limit' => '10', 'offset' => '0' }))
        .to_return(
          status: 200,
          body: {
            data: [{ customerId: 1, name: 'Customer 1' }],
            pagination: { limit: 10, offset: 0, hasNext: true }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      stub_request(:get, "#{api_base}/customers")
        .with(query: hash_including({ 'limit' => '10', 'offset' => '10' }))
        .to_return(
          status: 200,
          body: {
            data: [{ customerId: 2, name: 'Customer 2' }],
            pagination: { limit: 10, offset: 10, hasNext: false }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      page1 = Conexa::Customer.all(limit: 10)
      page2 = page1.next_page

      expect(page2).to be_a(Conexa::Result)
      expect(page2.data.first.name).to eq('Customer 2')
      expect(page2.pagination.offset).to eq(10)
      expect(page2.has_next?).to be false
    end

    it 'preserves original filter params' do
      stub_request(:get, "#{api_base}/customers")
        .with(query: hash_including({ 'limit' => '10', 'offset' => '0', 'isActive' => 'true' }))
        .to_return(
          status: 200,
          body: {
            data: [{ customerId: 1, name: 'Customer 1' }],
            pagination: { limit: 10, offset: 0, hasNext: true }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      stub_request(:get, "#{api_base}/customers")
        .with(query: hash_including({ 'limit' => '10', 'offset' => '10', 'isActive' => 'true' }))
        .to_return(
          status: 200,
          body: {
            data: [{ customerId: 2, name: 'Customer 2' }],
            pagination: { limit: 10, offset: 10, hasNext: false }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      page1 = Conexa::Customer.all(limit: 10, is_active: true)
      page2 = page1.next_page

      expect(page2.data.first.name).to eq('Customer 2')
    end

    it 'raises StopIteration when no more pages' do
      stub_request(:get, "#{api_base}/customers")
        .with(query: hash_including({ 'limit' => '10', 'offset' => '0' }))
        .to_return(
          status: 200,
          body: {
            data: [{ customerId: 1, name: 'Customer 1' }],
            pagination: { limit: 10, offset: 0, hasNext: false }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = Conexa::Customer.all(limit: 10)
      expect { result.next_page }.to raise_error(StopIteration, "No more pages")
    end

    it 'chains multiple next_page calls' do
      stub_request(:get, "#{api_base}/customers")
        .with(query: hash_including({ 'limit' => '5', 'offset' => '0' }))
        .to_return(
          status: 200,
          body: {
            data: [{ customerId: 1 }],
            pagination: { limit: 5, offset: 0, hasNext: true }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      stub_request(:get, "#{api_base}/customers")
        .with(query: hash_including({ 'limit' => '5', 'offset' => '5' }))
        .to_return(
          status: 200,
          body: {
            data: [{ customerId: 2 }],
            pagination: { limit: 5, offset: 5, hasNext: true }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      stub_request(:get, "#{api_base}/customers")
        .with(query: hash_including({ 'limit' => '5', 'offset' => '10' }))
        .to_return(
          status: 200,
          body: {
            data: [{ customerId: 3 }],
            pagination: { limit: 5, offset: 10, hasNext: false }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      page1 = Conexa::Customer.all(limit: 5)
      page2 = page1.next_page
      page3 = page2.next_page

      expect(page3.data.first.customer_id).to eq(3)
      expect(page3.has_next?).to be false
    end
  end

  describe 'new resources with new pagination' do
    it 'works with ReceivingMethod' do
      stub_request(:get, "#{api_base}/receivingMethods")
        .with(query: hash_including({ 'limit' => '10', 'offset' => '0' }))
        .to_return(
          status: 200,
          body: {
            data: [{ receivingMethodId: 10, name: 'Dinheiro', isActive: true }],
            pagination: { limit: 10, offset: 0, hasNext: false }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = Conexa::ReceivingMethod.all(limit: 10)

      expect(result.data.size).to eq(1)
      expect(result.data.first.name).to eq('Dinheiro')
      expect(result.pagination.has_next).to be false
    end

    it 'works with BillCategory' do
      stub_request(:get, "#{api_base}/billCategories")
        .with(query: hash_including({ 'limit' => '20', 'offset' => '0' }))
        .to_return(
          status: 200,
          body: {
            data: [{ billCategoryId: 4, name: 'Impostos' }],
            pagination: { limit: 20, offset: 0, hasNext: true }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = Conexa::BillCategory.all(limit: 20)

      expect(result.pagination.has_next).to be true
    end

    it 'works with Account' do
      stub_request(:get, "#{api_base}/accounts")
        .with(query: hash_including({ 'limit' => '50', 'offset' => '0' }))
        .to_return(
          status: 200,
          body: {
            data: [{ accountId: 1, name: 'Banco do Brasil' }],
            pagination: { limit: 50, offset: 0, hasNext: false }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = Conexa::Account.all(limit: 50)

      expect(result.data.first.name).to eq('Banco do Brasil')
    end
  end
end
