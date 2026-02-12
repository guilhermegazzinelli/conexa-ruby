# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Pagination Edge Cases' do
  let(:api_base) { 'https://checkbits.conexa.app' }

  before(:each) do
    Conexa.configure do |c|
      c.api_token = 'test_token'
      c.api_host = api_base
    end
  end

  describe 'Invalid page parameters' do
    context 'page 0' do
      it 'raises RequestError for page 0' do
        expect { Conexa::Customer.all(page: 0, size: 10) }
          .to raise_error(Conexa::RequestError, 'Invalid page size')
      end
    end

    context 'negative page' do
      it 'raises RequestError for negative page' do
        expect { Conexa::Customer.all(page: -1, size: 10) }
          .to raise_error(Conexa::RequestError, 'Invalid page size')
      end
    end

    context 'page -100' do
      it 'raises RequestError for large negative page' do
        expect { Conexa::Customer.all(page: -100, size: 10) }
          .to raise_error(Conexa::RequestError, 'Invalid page size')
      end
    end
  end

  describe 'Invalid size parameters' do
    context 'size 0' do
      it 'raises RequestError for size 0' do
        expect { Conexa::Customer.all(page: 1, size: 0) }
          .to raise_error(Conexa::RequestError, 'Invalid page size')
      end
    end

    context 'negative size' do
      it 'raises RequestError for negative size' do
        expect { Conexa::Customer.all(page: 1, size: -1) }
          .to raise_error(Conexa::RequestError, 'Invalid page size')
      end
    end

    context 'size -50' do
      it 'raises RequestError for large negative size' do
        expect { Conexa::Customer.all(page: 1, size: -50) }
          .to raise_error(Conexa::RequestError, 'Invalid page size')
      end
    end
  end

  describe 'Page greater than total_pages' do
    it 'returns empty result when page exceeds total' do
      stub_request(:get, "#{api_base}/customers")
        .with(query: hash_including({ 'page' => '999', 'size' => '10' }))
        .to_return(
          status: 200,
          body: {
            data: [],
            pagination: {
              page: 999,
              size: 10,
              totalPages: 5,
              totalElements: 50
            }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = Conexa::Customer.all(page: 999, size: 10)

      expect(result).to be_a(Conexa::Result)
      expect(result.empty?).to be true
      expect(result.pagination.total_pages).to eq(5)
    end
  end

  describe 'Empty response' do
    it 'handles response with no data' do
      stub_request(:get, "#{api_base}/customers")
        .with(query: hash_including({ 'page' => '1', 'size' => '10' }))
        .to_return(
          status: 200,
          body: {
            data: [],
            pagination: {
              page: 1,
              size: 10,
              totalPages: 0,
              totalElements: 0
            }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = Conexa::Customer.all(page: 1, size: 10)

      expect(result).to be_a(Conexa::Result)
      expect(result.empty?).to be true
      expect(result.data).to eq([])
      expect(result.pagination.total_elements).to eq(0)
    end

    it 'handles response with nil data' do
      stub_request(:get, "#{api_base}/customers")
        .with(query: hash_including({ 'page' => '1', 'size' => '10' }))
        .to_return(
          status: 200,
          body: {
            data: nil,
            pagination: {
              page: 1,
              size: 10,
              totalPages: 0,
              totalElements: 0
            }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = Conexa::Customer.all(page: 1, size: 10)

      expect(result).to be_a(Conexa::Result)
      expect(result.empty?).to be true
    end
  end

  describe 'Response with 1 item' do
    it 'handles single item response correctly' do
      stub_request(:get, "#{api_base}/customers")
        .with(query: hash_including({ 'page' => '1', 'size' => '10' }))
        .to_return(
          status: 200,
          body: {
            data: [{ id: 'cust-001', name: 'Single Customer' }],
            pagination: {
              page: 1,
              size: 10,
              totalPages: 1,
              totalElements: 1
            }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = Conexa::Customer.all(page: 1, size: 10)

      expect(result).to be_a(Conexa::Result)
      expect(result.empty?).to be false
      expect(result.data.size).to eq(1)
      expect(result.data.first.name).to eq('Single Customer')
      expect(result.pagination.total_elements).to eq(1)
    end
  end

  describe 'Response at size limit' do
    it 'handles response where size equals total' do
      customers = (1..10).map { |i| { id: "cust-#{i}", name: "Customer #{i}" } }

      stub_request(:get, "#{api_base}/customers")
        .with(query: hash_including({ 'page' => '1', 'size' => '10' }))
        .to_return(
          status: 200,
          body: {
            data: customers,
            pagination: {
              page: 1,
              size: 10,
              totalPages: 1,
              totalElements: 10
            }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = Conexa::Customer.all(page: 1, size: 10)

      expect(result).to be_a(Conexa::Result)
      expect(result.empty?).to be false
      expect(result.data.size).to eq(10)
      expect(result.pagination.total_elements).to eq(10)
      expect(result.pagination.total_pages).to eq(1)
    end
  end

  describe 'Large page size' do
    it 'handles very large size parameter' do
      stub_request(:get, "#{api_base}/customers")
        .with(query: hash_including({ 'page' => '1', 'size' => '10000' }))
        .to_return(
          status: 200,
          body: {
            data: [{ id: 'cust-1', name: 'Only Customer' }],
            pagination: {
              page: 1,
              size: 10000,
              totalPages: 1,
              totalElements: 1
            }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = Conexa::Customer.all(page: 1, size: 10000)

      expect(result.data.size).to eq(1)
      expect(result.pagination.size).to eq(10000)
    end
  end

  describe 'Default pagination' do
    it 'uses default page=1 and size=100 when not specified' do
      stub_request(:get, "#{api_base}/customers")
        .with(query: hash_including({ 'page' => '1', 'size' => '100' }))
        .to_return(
          status: 200,
          body: {
            data: [],
            pagination: { page: 1, size: 100, totalPages: 0, totalElements: 0 }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = Conexa::Customer.all

      expect(result.pagination.page).to eq(1)
      expect(result.pagination.size).to eq(100)
    end
  end

  describe 'Pagination info access' do
    it 'provides access to all pagination attributes' do
      stub_request(:get, "#{api_base}/customers")
        .with(query: hash_including({ 'page' => '2', 'size' => '25' }))
        .to_return(
          status: 200,
          body: {
            data: [{ id: 'cust-1' }],
            pagination: {
              page: 2,
              size: 25,
              totalPages: 10,
              totalElements: 250
            }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = Conexa::Customer.all(page: 2, size: 25)

      expect(result.pagination.page).to eq(2)
      expect(result.pagination.size).to eq(25)
      expect(result.pagination.total_pages).to eq(10)
      expect(result.pagination.total_elements).to eq(250)
    end
  end

  describe 'find_by with pagination' do
    it 'respects pagination in find_by' do
      stub_request(:get, "#{api_base}/customers")
        .with(query: hash_including({ 'page' => '3', 'size' => '5', 'status' => 'active' }))
        .to_return(
          status: 200,
          body: {
            data: [{ id: 'cust-1', status: 'active' }],
            pagination: { page: 3, size: 5, totalPages: 10, totalElements: 50 }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = Conexa::Customer.find_by({ status: 'active' }, 3, 5)

      expect(result.pagination.page).to eq(3)
      expect(result.pagination.size).to eq(5)
    end
  end
end
