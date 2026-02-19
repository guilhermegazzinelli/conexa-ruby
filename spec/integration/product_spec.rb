# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Product Integration" do
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

  let(:product_response) do
    {
      "productId" => 100,
      "companyId" => 3,
      "name" => "Mensalidade Coworking",
      "description" => "Mensalidade do espaco de coworking",
      "price" => 99.90
    }.to_json
  end

  let(:products_list_response) do
    {
      "data" => [
        { "productId" => 100, "name" => "Mensalidade Coworking", "companyId" => 3, "price" => 99.90 },
        { "productId" => 101, "name" => "Sala de Reuniao", "companyId" => 3, "price" => 50.00 },
        { "productId" => 102, "name" => "Endereco Fiscal", "companyId" => 3, "price" => 150.00 }
      ],
      "pagination" => { "currentPage" => 1, "totalPages" => 1, "totalItems" => 3, "itemPerPage" => 100 }
    }.to_json
  end

  describe "listing products" do
    before do
      stub_request(:get, /test\.conexa\.app.*products/)
        .to_return(status: 200, body: products_list_response, headers: { "Content-Type" => "application/json" })
    end

    it "returns a list of products" do
      result = Conexa::Product.all
      expect(result.data).to be_an(Array)
      expect(result.data.length).to eq(3)
    end

    it "returns product objects with attributes" do
      result = Conexa::Product.all
      product = result.data.first
      expect(product.name).to eq("Mensalidade Coworking")
      expect(product.company_id).to eq(3)
      expect(product.price).to eq(99.90)
    end
  end

  describe "finding a product" do
    before do
      stub_request(:get, /test\.conexa\.app.*product\/100/)
        .to_return(status: 200, body: product_response, headers: { "Content-Type" => "application/json" })
    end

    it "returns a product by id" do
      product = Conexa::Product.find(100)
      expect(product).to be_a(Conexa::Product)
      expect(product.name).to eq("Mensalidade Coworking")
      expect(product.description).to eq("Mensalidade do espaco de coworking")
    end
  end

  describe "read-only constraints" do
    it "cannot save a product" do
      product = Conexa::Product.new("productId" => 100, "name" => "Test")
      expect { product.save }.to raise_error(NoMethodError)
    end
  end
end
