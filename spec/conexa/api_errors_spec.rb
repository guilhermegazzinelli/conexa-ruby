# frozen_string_literal: true

require "spec_helper"

# The API answers errors in two shapes:
#
#   {"errors": [{"field": "date", "messages": ["Date cannot be blank"]}]}          400
#   {"errors": [{"code": "CHARGE_11", "message": "Only charges with..."}]}         422
#
# Request#run stringifies the whole array into the exception message, so nothing
# is lost — but there was no structured accessor, so every consumer reimplemented
# the formatting and the obvious implementation handles only the first shape.
# CONTRACT_RECURRING_SALE_10 rendered as an empty string for eight attempts
# because of exactly that.
RSpec.describe "API error normalisation" do
  let(:base) { "https://test.conexa.app/index.php/api/v2" }

  def error_from(status:, body:)
    stub_request(:post, "#{base}/contract").to_return(
      status: status, body: body.to_json, headers: { "Content-Type" => "application/json" }
    )
    Conexa::Request.post("/contract", params: { customer_id: 1 }).run
    nil
  rescue Conexa::ResponseError => e
    e
  end

  describe "field validation errors" do
    subject(:error) do
      error_from(status: 400, body: {
        message: "Field validation error",
        errors: [{ field: "date", messages: ["Date cannot be blank", "Date is invalid"] }]
      })
    end

    it "exposes them as structured entries" do
      expect(error.api_errors).to eq([{ field: "date", code: nil,
                                        message: "Date cannot be blank; Date is invalid" }])
    end

    it "has no error codes" do
      expect(error.api_error_codes).to be_empty
    end

    it "renders them readably" do
      expect(error.api_error_messages).to eq(["date: Date cannot be blank; Date is invalid"])
    end
  end

  describe "business-rule errors" do
    subject(:error) do
      error_from(status: 422, body: {
        message: "It was not possible to process your request",
        errors: [{ code: "CONTRACT_RECURRING_SALE_10",
                   message: "The due day can not be informed for customers who already have a contract" }]
      })
    end

    it "exposes the code, which is the part worth branching on" do
      expect(error.api_error_codes).to eq(["CONTRACT_RECURRING_SALE_10"])
    end

    it "renders the message rather than a blank string" do
      expect(error.api_error_messages)
        .to eq(["CONTRACT_RECURRING_SALE_10: The due day can not be informed for customers who already have a contract"])
    end

    it "keeps the raw body available" do
      expect(error.api_response["message"]).to eq("It was not possible to process your request")
    end
  end

  describe "both shapes at once" do
    subject(:error) do
      error_from(status: 400, body: {
        message: "Mixed",
        errors: [{ field: "accountId", messages: ["Account ID cannot be blank"] },
                 { code: "CHARGE_11", message: "Only charges with an open status can be settled." }]
      })
    end

    it "normalises them into one list" do
      expect(error.api_errors).to eq([
        { field: "accountId", code: nil, message: "Account ID cannot be blank" },
        { field: nil, code: "CHARGE_11", message: "Only charges with an open status can be settled." }
      ])
    end
  end

  describe "responses with no errors array" do
    subject(:error) { error_from(status: 403, body: { message: "You are not authorized to perform this action." }) }

    it "returns an empty list rather than raising" do
      expect(error.api_errors).to eq([])
      expect(error.api_error_codes).to eq([])
    end

    it "still carries the message" do
      expect(error.message).to include("You are not authorized")
    end
  end

  describe "NotFound" do
    it "inherits the same accessors" do
      stub_request(:get, "#{base}/contract/1").to_return(
        status: 404,
        body: { message: "This Contract does not exist or you have no permission to access it." }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

      expect { Conexa::Contract.find(1) }.to raise_error(Conexa::NotFound) { |e|
        expect(e.api_errors).to eq([])
        expect(e.api_response["message"]).to include("does not exist")
      }
    end
  end

  # The retry-safety case: after the empty-body fix a caller may still retry a
  # settlement, and CHARGE_11 is how it tells "already settled" from a real
  # failure.
  describe "using a code as control flow" do
    it "identifies an already-settled charge" do
      stub_request(:patch, "#{base}/charge/settle/555").to_return(
        status: 422,
        body: { message: "It was not possible to process your request",
                errors: [{ code: "CHARGE_11",
                           message: "Only charges with an open status can be settled." }] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

      already_settled = begin
        Conexa::Request.patch("/charge/settle/555", params: {}).run
        false
      rescue Conexa::ResponseError => e
        e.api_error_codes.include?("CHARGE_11")
      end

      expect(already_settled).to be(true)
    end
  end
end
