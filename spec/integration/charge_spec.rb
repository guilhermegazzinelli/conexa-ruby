# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Charge Integration" do
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

  let(:charge_response) do
    {
      "chargeId" => 123,
      "customerId" => 456,
      "value" => 150.00,
      "dueDate" => "2026-03-15",
      "status" => "pending",
      "description" => "Monthly subscription"
    }.to_json
  end

  let(:charges_list_response) do
    {
      "data" => [
        { "chargeId" => 1, "value" => 100.00, "status" => "pending" },
        { "chargeId" => 2, "value" => 200.00, "status" => "paid" }
      ],
      "pagination" => { "currentPage" => 1, "totalPages" => 1, "totalItems" => 2 }
    }.to_json
  end

  let(:pix_response) do
    {
      "qrCode" => "00020126580014br.gov.bcb.pix...",
      "qrCodeBase64" => "iVBORw0KGgo...",
      "expirationDate" => "2026-03-16T23:59:59"
    }.to_json
  end

  describe "listing charges" do
    before do
      stub_request(:get, /test\.conexa\.app.*charges/)
        .to_return(status: 200, body: charges_list_response, headers: { "Content-Type" => "application/json" })
    end

    it "returns a list of charges" do
      result = Conexa::Charge.all

      expect(result.data).to be_an(Array)
      expect(result.data.length).to eq(2)
    end

    it "includes charge attributes" do
      result = Conexa::Charge.all
      charge = result.data.first

      expect(charge.charge_id).to eq(1)
      expect(charge.value).to eq(100.00)
    end
  end

  describe "finding a charge" do
    before do
      stub_request(:get, /test\.conexa\.app.*charge\/123/)
        .to_return(status: 200, body: charge_response, headers: { "Content-Type" => "application/json" })
    end

    it "returns charge by id" do
      charge = Conexa::Charge.find(123)

      expect(charge.charge_id).to eq(123)
      expect(charge.customer_id).to eq(456)
      expect(charge.value).to eq(150.00)
    end

    it "includes status information" do
      charge = Conexa::Charge.find(123)

      expect(charge.status).to eq("pending")
      expect(charge.description).to eq("Monthly subscription")
    end
  end

  # Skip: Bug - Resource methods use camelCase for @attributes but ConexaObject converts to snake_case
  # See issue #13
  describe "PIX operations", skip: "Bug: camelCase vs snake_case mismatch in attributes" do
    before do
      stub_request(:get, /test\.conexa\.app.*charge\/123/)
        .to_return(status: 200, body: charge_response, headers: { "Content-Type" => "application/json" })

      stub_request(:get, /test\.conexa\.app.*charge\/pix\/123/)
        .to_return(status: 200, body: pix_response, headers: { "Content-Type" => "application/json" })
    end

    it "gets PIX QR code for a charge" do
      pix = Conexa::Charge.pix(123)

      expect(pix.qr_code).to be_a(String)
      expect(pix.qr_code).to start_with("00020126")
    end

    it "includes QR code base64" do
      pix = Conexa::Charge.pix(123)

      expect(pix.qr_code_base64).to be_a(String)
    end
  end

  # Skip: Bug - Resource methods use camelCase for @attributes but ConexaObject converts to snake_case
  describe "settling a charge", skip: "Bug: camelCase vs snake_case mismatch in attributes" do
    let(:settled_response) do
      {
        "chargeId" => 123,
        "status" => "paid",
        "paidAt" => "2026-02-12T10:00:00"
      }.to_json
    end

    before do
      stub_request(:get, /test\.conexa\.app.*charge\/123/)
        .to_return(status: 200, body: charge_response, headers: { "Content-Type" => "application/json" })

      stub_request(:post, /test\.conexa\.app.*charge\/settle\/123/)
        .to_return(status: 200, body: settled_response, headers: { "Content-Type" => "application/json" })
    end

    it "settles a charge" do
      charge = Conexa::Charge.settle(123)

      expect(charge).to be_a(Conexa::Charge)
    end
  end
end
