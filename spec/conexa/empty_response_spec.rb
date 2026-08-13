# frozen_string_literal: true

require "spec_helper"

# Regression cover for the most damaging defect in 0.1.1: a successful write that
# answers with an empty body was reported to the caller as a crash.
#
# `PATCH /charge/settle/:id` documents `204` with an empty body as its success
# response, and `PATCH /contract/end/:id` answers `200` with one. Request#run
# decoded either to nil and then called .dig on it, raising a bare NoMethodError
# — not a Conexa::ConexaError, so `rescue Conexa::ConexaError` did not catch it.
#
# In production that read as a failure for an operation that had already taken
# effect, and the retry it invited settled two charges twice and issued two NF-e.
RSpec.describe "responses with no body" do
  let(:base) { "https://test.conexa.app/index.php/api/v2" }

  describe Conexa::Request do
    # With the Oj adapter, MultiJson.decode("") returns nil *without* raising
    # ParseError — which is why the old `rescue MultiJson::ParseError` / 204
    # guard never fired, not even for a legitimate 204.
    {
      "an empty 200"       => { status: 200, body: "" },
      "a whitespace 200"   => { status: 200, body: "   " },
      "a literal null 200" => { status: 200, body: "null" },
      "an empty 204"       => { status: 204, body: "" },
      "an empty 201"       => { status: 201, body: "" }
    }.each do |label, response|
      it "returns {} for #{label}" do
        stub_request(:patch, "#{base}/charge/settle/555").to_return(**response)

        expect(Conexa::Request.patch("/charge/settle/555", params: {}).run).to eq({})
      end
    end

    it "still raises for a genuinely malformed body" do
      stub_request(:patch, "#{base}/charge/settle/555")
        .to_return(status: 200, body: "{ not json")

      expect { Conexa::Request.patch("/charge/settle/555", params: {}).run }
        .to raise_error(Conexa::ResponseError)
    end

    it "unwraps a top-level array body without calling dig on it" do
      stub_request(:get, "#{base}/charges").to_return(
        status: 200, body: '[{"chargeId":1}]',
        headers: { "Content-Type" => "application/json" }
      )

      expect(Conexa::Request.get("/charges").run)
        .to eq({ data: [{ "chargeId" => 1 }], pagination: nil })
    end
  end

  describe "through a resource" do
    before do
      stub_request(:get, "#{base}/charge/555").to_return(
        status: 200, body: '{"data":{"chargeId":555,"status":"pending"}}',
        headers: { "Content-Type" => "application/json" }
      )
    end

    it "settles a charge that answers 204 without raising" do
      stub_request(:patch, "#{base}/charge/settle/555").to_return(status: 204, body: "")

      charge = nil
      expect { charge = Conexa::Charge.settle(555, settlement_date: "2026-08-11") }
        .not_to raise_error
      expect(charge).to be_a(Conexa::Charge)
    end

    it "ends a contract that answers 200 with an empty body without raising" do
      stub_request(:get, "#{base}/contract/789").to_return(
        status: 200, body: '{"data":{"contractId":789,"status":"active"}}',
        headers: { "Content-Type" => "application/json" }
      )
      stub_request(:patch, "#{base}/contract/end/789").to_return(status: 200, body: "")

      expect { Conexa::Contract.end_contract(789, date: "2026-08-11") }.not_to raise_error
    end
  end
end
