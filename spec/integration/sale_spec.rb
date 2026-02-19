# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Sale Integration" do
  around(:each) do |example|
    VCR.turned_off do
      WebMock.enable!
      example.run
    end
  end

  before do
    Conexa.configure do |c|
      c.api_token = "test_token"
      c.api_host = "https://test.conexa.app"
    end
  end

  let(:sale_response) do
    {
      "saleId" => 188510,
      "customerId" => 450,
      "requesterId" => 458,
      "productId" => 2521,
      "sellerId" => 534,
      "status" => "notBilled",
      "quantity" => 1,
      "amount" => 80.99,
      "originalAmount" => 150.20,
      "discountValue" => 69.21,
      "referenceDate" => "2024-09-24T17:24:00-03:00",
      "notes" => "Venda avulsa",
      "createdAt" => "2024-09-24T17:24:00-03:00",
      "updatedAt" => "2024-09-26T19:12:19-03:00"
    }.to_json
  end

  let(:sales_list_response) do
    {
      "data" => [
        { "saleId" => 13, "amount" => 148.5, "status" => "notBilled", "customerId" => 14, "productId" => 2106 },
        { "saleId" => 14, "amount" => 54.0, "status" => "notBilled", "customerId" => 14, "productId" => 2106 },
        { "saleId" => 16, "amount" => 3.5, "status" => "billed", "customerId" => 14, "productId" => 2106 }
      ],
      "pagination" => { "currentPage" => 1, "totalPages" => 1, "totalItems" => 3, "itemPerPage" => 100 }
    }.to_json
  end

  describe "listing sales" do
    before do
      stub_request(:get, /test\.conexa\.app.*sales/)
        .to_return(status: 200, body: sales_list_response, headers: { "Content-Type" => "application/json" })
    end

    it "returns a list of sales with pagination" do
      result = Conexa::Sale.all
      expect(result.data).to be_an(Array)
      expect(result.data.length).to eq(3)
      expect(result.pagination).not_to be_nil
    end

    it "returns sale objects with attributes" do
      result = Conexa::Sale.all
      sale = result.data.first
      expect(sale.sale_id).to eq(13)
      expect(sale.amount).to eq(148.5)
      expect(sale.status).to eq("notBilled")
      expect(sale.customer_id).to eq(14)
    end
  end

  describe "finding a sale" do
    before do
      stub_request(:get, /test\.conexa\.app.*sale\/188510/)
        .to_return(status: 200, body: sale_response, headers: { "Content-Type" => "application/json" })
    end

    it "returns a sale by id" do
      sale = Conexa::Sale.find(188510)
      expect(sale).to be_a(Conexa::Sale)
      expect(sale.sale_id).to eq(188510)
      expect(sale.customer_id).to eq(450)
      expect(sale.amount).to eq(80.99)
    end

    it "includes all attributes" do
      sale = Conexa::Sale.find(188510)
      expect(sale.requester_id).to eq(458)
      expect(sale.seller_id).to eq(534)
      expect(sale.product_id).to eq(2521)
      expect(sale.original_amount).to eq(150.20)
      expect(sale.discount_value).to eq(69.21)
      expect(sale.notes).to eq("Venda avulsa")
    end
  end

  describe "creating a sale" do
    before do
      stub_request(:post, /test\.conexa\.app.*sale/)
        .to_return(status: 200, body: { "id" => 188510 }.to_json, headers: { "Content-Type" => "application/json" })

      stub_request(:get, /test\.conexa\.app.*sale\/188510/)
        .to_return(status: 200, body: sale_response, headers: { "Content-Type" => "application/json" })
    end

    it "creates a sale and returns it" do
      sale = Conexa::Sale.create(
        customer_id: 450,
        product_id: 2521,
        quantity: 1,
        amount: 80.99,
        reference_date: "2024-09-24",
        notes: "Venda avulsa"
      )
      expect(sale).to be_a(Conexa::Sale)
      expect(sale.sale_id).to eq(188510)
    end
  end

  describe "updating a sale" do
    before do
      stub_request(:get, /test\.conexa\.app.*sale\/188510/)
        .to_return(status: 200, body: sale_response, headers: { "Content-Type" => "application/json" })

      stub_request(:patch, /test\.conexa\.app.*sale\/188510/)
        .to_return(status: 200, body: sale_response.sub('"80.99"', '"90.00"'), headers: { "Content-Type" => "application/json" })
    end

    it "updates a sale" do
      sale = Conexa::Sale.find(188510)
      sale.amount = 90.00
      result = sale.save
      expect(result).to be_a(Conexa::Sale)
    end
  end

  describe "deleting a sale" do
    before do
      stub_request(:delete, /test\.conexa\.app.*sale\/188510/)
        .to_return(status: 200, body: sale_response, headers: { "Content-Type" => "application/json" })
    end

    it "deletes a sale by id" do
      result = Conexa::Sale.destroy(188510)
      expect(result).to be_a(Conexa::Sale)
    end
  end

  describe "helper methods" do
    it "editable? returns true for notBilled" do
      sale = Conexa::Sale.new("status" => "notBilled")
      expect(sale.editable?).to be true
    end

    it "editable? returns false for billed" do
      sale = Conexa::Sale.new("status" => "billed")
      expect(sale.editable?).to be false
    end

    it "billed? returns true for billed status" do
      sale = Conexa::Sale.new("status" => "billed")
      expect(sale.billed?).to be true
    end

    it "paid? returns true for paid status" do
      sale = Conexa::Sale.new("status" => "paid")
      expect(sale.paid?).to be true
    end

    it "paid? returns false for pending status" do
      sale = Conexa::Sale.new("status" => "notBilled")
      expect(sale.paid?).to be false
    end
  end
end
