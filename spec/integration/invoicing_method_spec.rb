# frozen_string_literal: true

require "spec_helper"

RSpec.describe "InvoicingMethod Integration" do
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

  let(:invoicing_method_response) do
    {
      "invoicingMethodId" => 1,
      "name" => "Boleto Bancario",
      "type" => "boleto",
      "isActive" => true
    }.to_json
  end

  let(:invoicing_methods_list_response) do
    {
      "data" => [
        { "invoicingMethodId" => 1, "name" => "Boleto Bancario", "type" => "boleto", "isActive" => true },
        { "invoicingMethodId" => 2, "name" => "PIX", "type" => "pix", "isActive" => true },
        { "invoicingMethodId" => 3, "name" => "Cartao de Credito", "type" => "credit_card", "isActive" => true }
      ],
      "pagination" => { "currentPage" => 1, "totalPages" => 1, "totalItems" => 3, "itemPerPage" => 100 }
    }.to_json
  end

  describe "listing invoicing methods" do
    before do
      stub_request(:get, /test\.conexa\.app.*invoicingMethods/)
        .to_return(status: 200, body: invoicing_methods_list_response, headers: { "Content-Type" => "application/json" })
    end

    it "returns a list of invoicing methods" do
      result = Conexa::InvoicingMethod.all
      expect(result.data).to be_an(Array)
      expect(result.data.length).to eq(3)
    end

    it "returns invoicing method objects with attributes" do
      result = Conexa::InvoicingMethod.all
      method = result.data.first
      expect(method.invoicing_method_id).to eq(1)
      expect(method.name).to eq("Boleto Bancario")
      expect(method.is_active).to be true
    end
  end

  describe "finding an invoicing method" do
    before do
      stub_request(:get, /test\.conexa\.app.*invoicingMethod\/1/)
        .to_return(status: 200, body: invoicing_method_response, headers: { "Content-Type" => "application/json" })
    end

    it "returns an invoicing method by id" do
      method = Conexa::InvoicingMethod.find(1)
      expect(method).to be_a(Conexa::InvoicingMethod)
      expect(method.invoicing_method_id).to eq(1)
      expect(method.name).to eq("Boleto Bancario")
    end
  end

  describe "creating an invoicing method" do
    before do
      stub_request(:post, /test\.conexa\.app.*invoicingMethod/)
        .to_return(status: 200, body: { "id" => 1 }.to_json, headers: { "Content-Type" => "application/json" })

      stub_request(:get, /test\.conexa\.app.*invoicingMethod\/1/)
        .to_return(status: 200, body: invoicing_method_response, headers: { "Content-Type" => "application/json" })
    end

    it "creates an invoicing method" do
      method = Conexa::InvoicingMethod.create(
        name: "Boleto Bancario",
        type: "boleto"
      )
      expect(method).to be_a(Conexa::InvoicingMethod)
      expect(method.name).to eq("Boleto Bancario")
    end
  end

  describe "updating an invoicing method" do
    before do
      stub_request(:get, /test\.conexa\.app.*invoicingMethod\/1/)
        .to_return(status: 200, body: invoicing_method_response, headers: { "Content-Type" => "application/json" })

      stub_request(:patch, /test\.conexa\.app.*invoicingMethod\/1/)
        .to_return(status: 200, body: invoicing_method_response, headers: { "Content-Type" => "application/json" })
    end

    it "updates an invoicing method" do
      method = Conexa::InvoicingMethod.find(1)
      method.name = "Novo Nome"
      result = method.save
      expect(result).to be_a(Conexa::InvoicingMethod)
    end
  end

  describe "deleting an invoicing method" do
    before do
      stub_request(:delete, /test\.conexa\.app.*invoicingMethod\/1/)
        .to_return(status: 200, body: invoicing_method_response, headers: { "Content-Type" => "application/json" })
    end

    it "deletes an invoicing method" do
      result = Conexa::InvoicingMethod.destroy(1)
      expect(result).to be_a(Conexa::InvoicingMethod)
    end
  end
end
