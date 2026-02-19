# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Company Integration" do
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

  let(:company_response) do
    {
      "companyId" => 3,
      "name" => "Unidade Centro",
      "tradeName" => "Centro BH",
      "cnpj" => "12.345.678/0001-90",
      "address" => {
        "zipCode" => "30130000",
        "state" => "MG",
        "city" => "Belo Horizonte",
        "street" => "Av. Afonso Pena",
        "number" => "1000",
        "neighborhood" => "Centro"
      }
    }.to_json
  end

  let(:companies_list_response) do
    {
      "data" => [
        { "companyId" => 1, "name" => "Matriz" },
        { "companyId" => 3, "name" => "Unidade Centro" },
        { "companyId" => 5, "name" => "Unidade Savassi" }
      ],
      "pagination" => { "currentPage" => 1, "totalPages" => 1, "totalItems" => 3, "itemPerPage" => 100 }
    }.to_json
  end

  describe "listing companies" do
    before do
      stub_request(:get, /test\.conexa\.app.*companys/)
        .to_return(status: 200, body: companies_list_response, headers: { "Content-Type" => "application/json" })
    end

    it "returns a list of companies" do
      result = Conexa::Company.all
      expect(result.data).to be_an(Array)
      expect(result.data.length).to eq(3)
    end

    it "returns company objects with attributes" do
      result = Conexa::Company.all
      company = result.data[1]
      expect(company.name).to eq("Unidade Centro")
    end
  end

  describe "finding a company" do
    before do
      stub_request(:get, /test\.conexa\.app.*company\/3/)
        .to_return(status: 200, body: company_response, headers: { "Content-Type" => "application/json" })
    end

    it "returns a company by id" do
      company = Conexa::Company.find(3)
      expect(company).to be_a(Conexa::Company)
      expect(company.name).to eq("Unidade Centro")
      expect(company.trade_name).to eq("Centro BH")
      expect(company.cnpj).to eq("12.345.678/0001-90")
    end

    it "includes nested address" do
      company = Conexa::Company.find(3)
      expect(company.address).not_to be_nil
      expect(company.address.city).to eq("Belo Horizonte")
    end
  end
end
