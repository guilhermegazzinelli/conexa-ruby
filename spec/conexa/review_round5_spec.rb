# frozen_string_literal: true

require "spec_helper"

# Three gaps left open by round four, plus the consequence of probing the live
# API: a spec suite can only be as honest as the endpoints it believes in.
RSpec.describe "review round 5" do
  let(:base) { "https://test.conexa.app/index.php/api/v2" }
  let(:json) { { "Content-Type" => "application/json" } }

  # API v2 exposes no read for credit cards. Verified against a live tenant on
  # 2026-08-12: `GET /creditCard` answers "Unable to resolve the request" (the
  # same message as a route that does not exist at all) and `GET /creditCard/:id`
  # answers "unable to find the requested action \"view\"" — the controller is
  # there, the action is not. Neither is the "does not exist or you have no
  # permission" wording the API uses for a resource the account cannot see, and
  # the collection documents a 403 for authorization, so this is API surface
  # rather than a disabled feature.
  describe Conexa::CreditCard do
    it "refuses to list, explaining why" do
      expect { described_class.all }.to raise_error(Conexa::RequestError, /não expõe leitura/)
    end

    it "refuses to find, explaining why" do
      expect { described_class.find(99) }.to raise_error(Conexa::RequestError, /não expõe leitura/)
    end

    it "refuses through every alias" do
      expect { described_class.where }.to raise_error(Conexa::RequestError)
      expect { described_class.find_by }.to raise_error(Conexa::RequestError)
      expect { described_class.find_by_id(1) }.to raise_error(Conexa::RequestError)
    end

    # POST /creditCard is real and documented. Model#create re-fetches after
    # creating, which would hit the read that does not exist.
    it "still creates, without trying to re-read" do
      stub_request(:post, "#{base}/creditCard").to_return(
        status: 201, body: '{"id":5}', headers: json
      )

      card = described_class.create(customer_id: 127, number: "4111", cvc: "123",
                                    expiration_date: "12/26", name: "J DA SILVA")

      expect(card).to be_a(described_class)
      expect(card.id).to eq(5)
    end
  end

  # `Request#call` yields nil for an empty body, so a listing returned nil rather
  # than the Conexa::Result the READMEs promise, and a caller chaining .data or
  # .next_page got a NoMethodError far from the cause.
  describe "listings always answer with a Result" do
    it "returns an empty Result when the body is empty" do
      stub_request(:get, %r{#{Regexp.escape(base)}/customers}).to_return(status: 200, body: "")

      result = Conexa::Customer.all(limit: 5)

      expect(result).to be_a(Conexa::Result)
      expect(result).to be_empty
      expect(result.data).to eq([])
      expect(result.has_next?).to be(false)
    end

    it "wraps a bare array body in a Result" do
      stub_request(:get, %r{#{Regexp.escape(base)}/customers}).to_return(
        status: 200, body: '[{"customerId":1}]', headers: json
      )

      result = Conexa::Customer.all(limit: 5)

      expect(result).to be_a(Conexa::Result)
      expect(result.data.size).to eq(1)
    end

    it "leaves a normal paginated response alone" do
      stub_request(:get, %r{#{Regexp.escape(base)}/customers}).to_return(
        status: 200,
        body: '{"data":[{"customerId":1}],"pagination":{"limit":5,"offset":0,"hasNext":false}}',
        headers: json
      )

      result = Conexa::Customer.all(limit: 5)

      expect(result).to be_a(Conexa::Result)
      expect(result.pagination.limit).to eq(5)
    end
  end

  # The nil-guard added to #update in round three made this silent: a refresh
  # that came back with nothing kept the stale attributes and reported success.
  # For a refresh — unlike a write — "the server said nothing" is not a valid
  # answer.
  describe "refreshing against an empty body" do
    it "raises rather than keeping stale attributes" do
      stub_request(:get, "#{base}/charge/7").to_return(
        status: 200, body: '{"data":{"chargeId":7,"status":"pending"}}', headers: json
      )
      charge = Conexa::Charge.find(7)

      stub_request(:get, "#{base}/charge/7").to_return(status: 200, body: "")

      expect { charge.fetch }.to raise_error(Conexa::ResponseError, /nada para atualizar/)
    end

    it "still refreshes normally when the body is there" do
      stub_request(:get, "#{base}/charge/7").to_return(
        status: 200, body: '{"data":{"chargeId":7,"status":"pending"}}', headers: json
      )
      charge = Conexa::Charge.find(7)

      stub_request(:get, "#{base}/charge/7").to_return(
        status: 200, body: '{"data":{"chargeId":7,"status":"paid"}}', headers: json
      )

      expect(charge.fetch.status).to eq("paid")
    end
  end
end
