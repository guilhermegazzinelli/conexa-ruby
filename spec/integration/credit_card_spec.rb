# frozen_string_literal: true

require "spec_helper"

RSpec.describe "CreditCard Integration" do
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

  let(:credit_card_response) do
    {
      "creditCardId" => 99,
      "customerId" => 127,
      "brand" => "visa",
      "lastFourDigits" => "1111",
      "name" => "JOAO DA SILVA",
      "expirationDate" => "12/2026",
      "default" => true,
      "enableRecurring" => true
    }.to_json
  end

  describe "finding a credit card" do
    before do
      stub_request(:get, /test\.conexa\.app.*creditCard\/99/)
        .to_return(status: 200, body: credit_card_response, headers: { "Content-Type" => "application/json" })
    end

    it "returns a credit card by id" do
      card = Conexa::CreditCard.find(99)
      expect(card).to be_a(Conexa::CreditCard)
      expect(card.credit_card_id).to eq(99)
      expect(card.customer_id).to eq(127)
      expect(card.brand).to eq("visa")
      expect(card.name).to eq("JOAO DA SILVA")
      expect(card.default).to be true
    end
  end

  describe "creating a credit card" do
    before do
      stub_request(:post, /test\.conexa\.app.*creditCard/)
        .to_return(status: 200, body: { "id" => 99 }.to_json, headers: { "Content-Type" => "application/json" })

      stub_request(:get, /test\.conexa\.app.*creditCard\/99/)
        .to_return(status: 200, body: credit_card_response, headers: { "Content-Type" => "application/json" })
    end

    it "creates a credit card" do
      card = Conexa::CreditCard.create(
        customer_id: 127,
        number: "4111111111111111",
        name: "JOAO DA SILVA",
        expiration_date: "12/2026",
        cvc: "123",
        brand: "visa",
        default: true,
        enable_recurring: true
      )
      expect(card).to be_a(Conexa::CreditCard)
      expect(card.credit_card_id).to eq(99)
      expect(card.brand).to eq("visa")
    end
  end

  describe "updating a credit card" do
    before do
      stub_request(:get, /test\.conexa\.app.*creditCard\/99/)
        .to_return(status: 200, body: credit_card_response, headers: { "Content-Type" => "application/json" })

      stub_request(:patch, /test\.conexa\.app.*creditCard\/99/)
        .to_return(status: 200, body: credit_card_response, headers: { "Content-Type" => "application/json" })
    end

    it "updates a credit card" do
      card = Conexa::CreditCard.find(99)
      card.default = false
      result = card.save
      expect(result).to be_a(Conexa::CreditCard)
    end
  end

  describe "deleting a credit card" do
    before do
      stub_request(:delete, /test\.conexa\.app.*creditCard\/99/)
        .to_return(status: 200, body: credit_card_response, headers: { "Content-Type" => "application/json" })
    end

    it "deletes a credit card" do
      result = Conexa::CreditCard.destroy(99)
      expect(result).to be_a(Conexa::CreditCard)
    end
  end
end
