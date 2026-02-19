# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Supplier Integration" do
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

  let(:supplier_response) do
    {
      "supplierId" => 50,
      "name" => "Fornecedor XYZ Ltda",
      "fieldOfActivity" => "Servicos",
      "cellNumber" => "31999998888",
      "phones" => ["3133334444"],
      "emails" => ["contato@xyz.com.br"],
      "website" => "https://www.xyz.com.br",
      "legalPerson" => {
        "legalName" => "Fornecedor XYZ Servicos Ltda",
        "cnpj" => "12.345.678/0001-90",
        "stateInscription" => "123456789"
      },
      "address" => {
        "zipCode" => "30130000",
        "state" => "MG",
        "city" => "Belo Horizonte",
        "street" => "Rua da Bahia",
        "number" => "500",
        "neighborhood" => "Centro"
      }
    }.to_json
  end

  let(:suppliers_list_response) do
    {
      "data" => [
        { "supplierId" => 50, "name" => "Fornecedor XYZ Ltda" },
        { "supplierId" => 51, "name" => "Fornecedor ABC" }
      ],
      "pagination" => { "currentPage" => 1, "totalPages" => 1, "totalItems" => 2, "itemPerPage" => 100 }
    }.to_json
  end

  describe "listing suppliers" do
    before do
      stub_request(:get, /test\.conexa\.app.*supplier\b/)
        .to_return(status: 200, body: suppliers_list_response, headers: { "Content-Type" => "application/json" })
    end

    it "returns a list of suppliers" do
      result = Conexa::Supplier.all
      expect(result.data).to be_an(Array)
      expect(result.data.length).to eq(2)
    end

    it "returns supplier objects with attributes" do
      result = Conexa::Supplier.all
      supplier = result.data.first
      expect(supplier.name).to eq("Fornecedor XYZ Ltda")
    end
  end

  describe "finding a supplier" do
    before do
      stub_request(:get, /test\.conexa\.app.*supplier\/50/)
        .to_return(status: 200, body: supplier_response, headers: { "Content-Type" => "application/json" })
    end

    it "returns a supplier by id" do
      supplier = Conexa::Supplier.find(50)
      expect(supplier).to be_a(Conexa::Supplier)
      expect(supplier.name).to eq("Fornecedor XYZ Ltda")
      expect(supplier.field_of_activity).to eq("Servicos")
      expect(supplier.cell_number).to eq("31999998888")
    end

    it "includes nested legal person data" do
      supplier = Conexa::Supplier.find(50)
      expect(supplier.legal_person).not_to be_nil
      expect(supplier.legal_person.cnpj).to eq("12.345.678/0001-90")
    end

    it "includes nested address data" do
      supplier = Conexa::Supplier.find(50)
      expect(supplier.address).not_to be_nil
      expect(supplier.address.city).to eq("Belo Horizonte")
      expect(supplier.address.state).to eq("MG")
    end
  end

  describe "creating a supplier" do
    before do
      stub_request(:post, /test\.conexa\.app.*supplier/)
        .to_return(status: 200, body: { "id" => 50 }.to_json, headers: { "Content-Type" => "application/json" })

      stub_request(:get, /test\.conexa\.app.*supplier\/50/)
        .to_return(status: 200, body: supplier_response, headers: { "Content-Type" => "application/json" })
    end

    it "creates a supplier with legal person data" do
      supplier = Conexa::Supplier.create(
        name: "Fornecedor XYZ Ltda",
        legal_person: { cnpj: "12.345.678/0001-90" },
        address: { zip_code: "30130000", state: "MG", city: "Belo Horizonte" }
      )
      expect(supplier).to be_a(Conexa::Supplier)
      expect(supplier.name).to eq("Fornecedor XYZ Ltda")
    end
  end

  describe "updating a supplier" do
    before do
      stub_request(:get, /test\.conexa\.app.*supplier\/50/)
        .to_return(status: 200, body: supplier_response, headers: { "Content-Type" => "application/json" })

      stub_request(:patch, /test\.conexa\.app.*supplier\/50/)
        .to_return(status: 200, body: supplier_response, headers: { "Content-Type" => "application/json" })
    end

    it "updates a supplier" do
      supplier = Conexa::Supplier.find(50)
      supplier.name = "Novo Nome"
      result = supplier.save
      expect(result).to be_a(Conexa::Supplier)
    end
  end

  describe "deleting a supplier" do
    before do
      stub_request(:delete, /test\.conexa\.app.*supplier\/50/)
        .to_return(status: 200, body: supplier_response, headers: { "Content-Type" => "application/json" })
    end

    it "deletes a supplier" do
      result = Conexa::Supplier.destroy(50)
      expect(result).to be_a(Conexa::Supplier)
    end
  end
end
