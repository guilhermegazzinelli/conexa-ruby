# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Person Integration" do
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

  let(:person_response) do
    {
      "personId" => 458,
      "customerId" => 127,
      "name" => "Maria Solicitante",
      "cpf" => "123.456.789-00",
      "rg" => "123456789",
      "birthDate" => "1990-05-15",
      "cellNumber" => "31999998888",
      "phones" => ["3133334444"],
      "emails" => ["maria@empresa.com"],
      "sex" => "female",
      "jobTitle" => "Gerente",
      "profession" => "Administradora",
      "hasLoginAccess" => true,
      "isCompanyPartner" => true,
      "address" => {
        "zipCode" => "30130000",
        "state" => "MG",
        "city" => "Belo Horizonte",
        "street" => "Av. Afonso Pena",
        "number" => "1000"
      }
    }.to_json
  end

  let(:persons_list_response) do
    {
      "data" => [
        { "personId" => 458, "name" => "Maria Solicitante", "customerId" => 127 },
        { "personId" => 459, "name" => "Joao Silva", "customerId" => 127 }
      ],
      "pagination" => { "currentPage" => 1, "totalPages" => 1, "totalItems" => 2, "itemPerPage" => 100 }
    }.to_json
  end

  describe "listing persons" do
    before do
      stub_request(:get, /test\.conexa\.app.*persons/)
        .to_return(status: 200, body: persons_list_response, headers: { "Content-Type" => "application/json" })
    end

    it "returns a list of persons" do
      result = Conexa::Person.all
      expect(result.data).to be_an(Array)
      expect(result.data.length).to eq(2)
    end

    it "returns person objects with attributes" do
      result = Conexa::Person.all
      person = result.data.first
      expect(person.name).to eq("Maria Solicitante")
      expect(person.customer_id).to eq(127)
    end
  end

  describe "finding a person" do
    before do
      stub_request(:get, /test\.conexa\.app.*person\/458/)
        .to_return(status: 200, body: person_response, headers: { "Content-Type" => "application/json" })
    end

    it "returns a person by id" do
      person = Conexa::Person.find(458)
      expect(person).to be_a(Conexa::Person)
      expect(person.name).to eq("Maria Solicitante")
      expect(person.cpf).to eq("123.456.789-00")
    end

    it "includes nested address" do
      person = Conexa::Person.find(458)
      expect(person.address).not_to be_nil
      expect(person.address.city).to eq("Belo Horizonte")
    end
  end

  describe "creating a person" do
    before do
      stub_request(:post, /test\.conexa\.app.*person/)
        .to_return(status: 200, body: { "id" => 458 }.to_json, headers: { "Content-Type" => "application/json" })

      stub_request(:get, /test\.conexa\.app.*person\/458/)
        .to_return(status: 200, body: person_response, headers: { "Content-Type" => "application/json" })
    end

    it "creates a person with full data" do
      person = Conexa::Person.create(
        customer_id: 127,
        name: "Maria Solicitante",
        cpf: "123.456.789-00",
        birth_date: "1990-05-15",
        cell_number: "31999998888",
        emails: ["maria@empresa.com"],
        sex: "female",
        job_title: "Gerente",
        profession: "Administradora",
        has_login_access: true,
        login: "maria@empresa.com",
        password: "SecurePass123",
        permissions: ["finance", "orders"],
        address: {
          zip_code: "30130000",
          state: "MG",
          city: "Belo Horizonte"
        }
      )
      expect(person).to be_a(Conexa::Person)
      expect(person.name).to eq("Maria Solicitante")
      expect(person.customer_id).to eq(127)
    end
  end

  describe "updating a person" do
    before do
      stub_request(:get, /test\.conexa\.app.*person\/458/)
        .to_return(status: 200, body: person_response, headers: { "Content-Type" => "application/json" })

      stub_request(:patch, /test\.conexa\.app.*person\/458/)
        .to_return(status: 200, body: person_response, headers: { "Content-Type" => "application/json" })
    end

    it "updates a person" do
      person = Conexa::Person.find(458)
      person.name = "Maria Solicitante"
      result = person.save
      expect(result).to be_a(Conexa::Person)
    end
  end

  describe "deleting a person" do
    before do
      stub_request(:delete, /test\.conexa\.app.*person\/458/)
        .to_return(status: 200, body: person_response, headers: { "Content-Type" => "application/json" })
    end

    it "deletes a person" do
      result = Conexa::Person.destroy(458)
      expect(result).to be_a(Conexa::Person)
    end
  end
end
