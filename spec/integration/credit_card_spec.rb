# frozen_string_literal: true

require "spec_helper"

# This file used to stub `GET /creditCard/:id`, `PATCH /creditCard/:id` and
# `DELETE /creditCard/:id` and assert they worked. None of those endpoints
# exist — the stubs invented them, and the suite was green over an API surface
# that is not there. Probing a live tenant on 2026-08-12 settled it:
#
#   GET /creditCard      => 404 "Unable to resolve the request"
#   GET /creditCard/:id  => 404 "unable to find the requested action \"view\""
#
# The collection documents `POST /creditCard` and nothing else, which is
# consistent: the number and CVC live encrypted at Cielo, so there is nothing to
# read back.
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

  describe "registering a card" do
    let!(:create_stub) do
      stub_request(:post, "https://test.conexa.app/index.php/api/v2/creditCard")
        .to_return(status: 201, body: { "id" => 99 }.to_json,
                   headers: { "Content-Type" => "application/json" })
    end

    it "posts the documented fields, camelized" do
      Conexa::CreditCard.create(
        customer_id: 127,
        number: "4111111111111111",
        name: "JOAO DA SILVA",
        expiration_date: "12/26",
        cvc: "123",
        brand: "visa",
        default: true,
        enable_recurring: true
      )

      documented = %w[brand customerId cvc default enableRecurring
                      expirationDate name number].sort

      expect(create_stub).to have_been_requested
      expect(WebMock).to(have_requested(:post, %r{/creditCard})
        .with { |request| JSON.parse(request.body).keys.sort == documented })
    end

    it "keeps the id the API returns" do
      card = Conexa::CreditCard.create(customer_id: 127, number: "4111", cvc: "1",
                                       expiration_date: "12/26", name: "J")

      expect(card).to be_a(Conexa::CreditCard)
      expect(card.id).to eq(99)
    end

    # Model#create re-fetches to pick up server-side defaults. Here that would
    # hit the read that does not exist, so CreditCard overrides it.
    it "does not try to read the card back" do
      Conexa::CreditCard.create(customer_id: 127, number: "4111", cvc: "1",
                                expiration_date: "12/26", name: "J")

      expect(WebMock).not_to have_requested(:get, %r{/creditCard})
    end
  end

  describe "reading" do
    it "refuses instead of requesting an endpoint that does not exist" do
      expect { Conexa::CreditCard.find(99) }
        .to raise_error(Conexa::RequestError, /não expõe leitura/)

      expect(WebMock).not_to have_requested(:get, %r{/creditCard})
    end

    it "refuses to list" do
      expect { Conexa::CreditCard.all }.to raise_error(Conexa::RequestError)
    end
  end
end
