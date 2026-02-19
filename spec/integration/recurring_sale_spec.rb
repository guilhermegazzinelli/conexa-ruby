# frozen_string_literal: true

require "spec_helper"

RSpec.describe "RecurringSale Integration" do
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

  let(:recurring_sale_response) do
    {
      "recurringSaleId" => 555,
      "customerId" => 127,
      "type" => "product",
      "referenceId" => 100,
      "requesterId" => 10,
      "sellerId" => 1,
      "isRepeat" => true,
      "frequency" => "monthly",
      "startDate" => "2024-01-01",
      "quantity" => 1,
      "amount" => 99.90,
      "notes" => "Venda recorrente"
    }.to_json
  end

  let(:recurring_sales_list_response) do
    {
      "data" => [
        { "recurringSaleId" => 555, "amount" => 99.90, "customerId" => 127, "frequency" => "monthly" },
        { "recurringSaleId" => 556, "amount" => 200.00, "customerId" => 128, "frequency" => "yearly" }
      ],
      "pagination" => { "currentPage" => 1, "totalPages" => 1, "totalItems" => 2, "itemPerPage" => 100 }
    }.to_json
  end

  describe "listing recurring sales" do
    before do
      stub_request(:get, /test\.conexa\.app.*recurringSales/)
        .to_return(status: 200, body: recurring_sales_list_response, headers: { "Content-Type" => "application/json" })
    end

    it "returns a list of recurring sales" do
      result = Conexa::RecurringSale.all
      expect(result.data).to be_an(Array)
      expect(result.data.length).to eq(2)
    end

    it "returns recurring sale objects with attributes" do
      result = Conexa::RecurringSale.all
      rs = result.data.first
      expect(rs.recurring_sale_id).to eq(555)
      expect(rs.amount).to eq(99.90)
      expect(rs.frequency).to eq("monthly")
    end
  end

  describe "finding a recurring sale" do
    before do
      stub_request(:get, /test\.conexa\.app.*recurringSale\/555/)
        .to_return(status: 200, body: recurring_sale_response, headers: { "Content-Type" => "application/json" })
    end

    it "returns a recurring sale by id" do
      rs = Conexa::RecurringSale.find(555)
      expect(rs).to be_a(Conexa::RecurringSale)
      expect(rs.recurring_sale_id).to eq(555)
      expect(rs.customer_id).to eq(127)
      expect(rs.amount).to eq(99.90)
      expect(rs.type).to eq("product")
    end
  end

  describe "creating a recurring sale" do
    before do
      stub_request(:post, /test\.conexa\.app.*recurringSale/)
        .to_return(status: 200, body: { "id" => 555 }.to_json, headers: { "Content-Type" => "application/json" })

      stub_request(:get, /test\.conexa\.app.*recurringSale\/555/)
        .to_return(status: 200, body: recurring_sale_response, headers: { "Content-Type" => "application/json" })
    end

    it "creates a recurring sale" do
      rs = Conexa::RecurringSale.create(
        customer_id: 127,
        type: "product",
        reference_id: 100,
        quantity: 1,
        amount: 99.90,
        frequency: "monthly",
        start_date: "2024-01-01"
      )
      expect(rs).to be_a(Conexa::RecurringSale)
      expect(rs.recurring_sale_id).to eq(555)
    end
  end

  describe "ending a recurring sale" do
    let(:ended_response) do
      { "recurringSaleId" => 555, "status" => "ended" }.to_json
    end

    before do
      stub_request(:get, /test\.conexa\.app.*recurringSale\/555/)
        .to_return(status: 200, body: recurring_sale_response, headers: { "Content-Type" => "application/json" })

      stub_request(:post, /test\.conexa\.app.*recurringSale\/end\/555/)
        .to_return(status: 200, body: ended_response, headers: { "Content-Type" => "application/json" })
    end

    it "ends a recurring sale via class method" do
      result = Conexa::RecurringSale.end_recurring_sale(555, date: "2024-12-31")
      expect(result).to be_a(Conexa::RecurringSale)
    end

    it "ends a recurring sale via instance method" do
      rs = Conexa::RecurringSale.find(555)
      result = rs.end_recurring_sale(date: "2024-12-31")
      expect(result).to be_a(Conexa::RecurringSale)
    end
  end

  describe "deleting a recurring sale" do
    before do
      stub_request(:delete, /test\.conexa\.app.*recurringSale\/555/)
        .to_return(status: 200, body: recurring_sale_response, headers: { "Content-Type" => "application/json" })
    end

    it "deletes a recurring sale" do
      result = Conexa::RecurringSale.destroy(555)
      expect(result).to be_a(Conexa::RecurringSale)
    end
  end
end
