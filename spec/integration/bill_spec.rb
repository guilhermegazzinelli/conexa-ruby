# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Bill Integration" do
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

  let(:bill_response) do
    {
      "billId" => 321,
      "companyId" => 1,
      "dueDate" => "2024-03-15",
      "amount" => 500.00,
      "supplierId" => 50,
      "description" => "Aluguel escritorio",
      "documentNumber" => "NF-001",
      "status" => "pending"
    }.to_json
  end

  let(:bills_list_response) do
    {
      "data" => [
        { "billId" => 321, "amount" => 500.00, "description" => "Aluguel", "status" => "pending" },
        { "billId" => 322, "amount" => 150.00, "description" => "Internet", "status" => "paid" }
      ],
      "pagination" => { "currentPage" => 1, "totalPages" => 1, "totalItems" => 2, "itemPerPage" => 100 }
    }.to_json
  end

  describe "listing bills" do
    before do
      stub_request(:get, /test\.conexa\.app.*bills/)
        .to_return(status: 200, body: bills_list_response, headers: { "Content-Type" => "application/json" })
    end

    it "returns a list of bills" do
      result = Conexa::Bill.all
      expect(result.data).to be_an(Array)
      expect(result.data.length).to eq(2)
    end

    it "returns bill objects with attributes" do
      result = Conexa::Bill.all
      bill = result.data.first
      expect(bill.amount).to eq(500.00)
      expect(bill.description).to eq("Aluguel")
    end
  end

  describe "finding a bill" do
    before do
      stub_request(:get, /test\.conexa\.app.*bill\/321/)
        .to_return(status: 200, body: bill_response, headers: { "Content-Type" => "application/json" })
    end

    it "returns a bill by id" do
      bill = Conexa::Bill.find(321)
      expect(bill).to be_a(Conexa::Bill)
      expect(bill.amount).to eq(500.00)
      expect(bill.description).to eq("Aluguel escritorio")
      expect(bill.supplier_id).to eq(50)
      expect(bill.document_number).to eq("NF-001")
    end
  end

  describe "creating a bill" do
    before do
      stub_request(:post, /test\.conexa\.app.*bill/)
        .to_return(status: 200, body: { "id" => 321 }.to_json, headers: { "Content-Type" => "application/json" })

      stub_request(:get, /test\.conexa\.app.*bill\/321/)
        .to_return(status: 200, body: bill_response, headers: { "Content-Type" => "application/json" })
    end

    it "creates a bill" do
      bill = Conexa::Bill.create(
        company_id: 1,
        due_date: "2024-03-15",
        amount: 500.00,
        supplier_id: 50,
        description: "Aluguel escritorio"
      )
      expect(bill).to be_a(Conexa::Bill)
      expect(bill.amount).to eq(500.00)
    end
  end

  describe "read-only constraints" do
    it "cannot save a bill" do
      bill = Conexa::Bill.new("billId" => 321, "amount" => 500)
      expect { bill.save }.to raise_error(NoMethodError)
    end
  end
end
