# frozen_string_literal: true

require "spec_helper"

# Issue #23. Predicates that test a `status` value the API never sends are dead
# code, and they fail in the direction that writes: "is there already an active
# contract?" answering false is what makes a caller create a second one.
#
# Every enum below was checked against a live tenant — the API validates the
# filter and names the accepted values in the 400, so the real set is knowable
# without guessing.
RSpec.describe "status predicates" do
  let(:json) { { "Content-Type" => "application/json" } }

  # Contracts carry `isActive` (boolean) and `endDate`. There is no `status`.
  describe Conexa::Contract do
    it "is active when the API says isActive" do
      expect(described_class.new("is_active" => true)).to be_active
    end

    it "is not active when the API says otherwise" do
      expect(described_class.new("is_active" => false)).not_to be_active
    end

    it "is ended when isActive is false" do
      expect(described_class.new("is_active" => false)).to be_ended
    end

    it "is not ended while active" do
      expect(described_class.new("is_active" => true)).not_to be_ended
    end

    # The active contract 281 on the live tenant carries endDate 2026-11-30.
    # A future end date is a scheduled close, not a closed contract — reading
    # `end_date` as "ended" would invert the answer.
    it "stays active when an end date is merely scheduled" do
      contract = described_class.new("is_active" => true, "end_date" => "2099-12-31")

      expect(contract).to be_active
      expect(contract).not_to be_ended
    end

    # A contract fetched from an endpoint that omits the field must not silently
    # claim to be closed.
    it "returns nil rather than guessing when isActive is absent" do
      contract = described_class.new("contract_id" => 1)

      expect(contract.active?).to be_nil
      expect(contract.ended?).to be_nil
    end

    it "no longer answers to a status that does not exist" do
      expect(described_class.new("is_active" => true).status).to be_nil
    end
  end

  # The API rejects `pending` and `overdue` outright:
  #   status=pending -> 400 "Status is not on the list (unpaid, negotiated,
  #                     generatedByNegotiation, cancelled, paid, denied, ...)"
  describe Conexa::Charge do
    it "is paid on the documented value" do
      expect(described_class.new("status" => "paid")).to be_paid
    end

    it "is unpaid on the documented value, which is not called pending" do
      expect(described_class.new("status" => "unpaid")).to be_unpaid
    end

    it "keeps pending? as a deprecated alias of unpaid?" do
      charge = described_class.new("status" => "unpaid")

      expect { expect(charge).to be_pending }.to output(/unpaid/).to_stderr
    end

    it "is cancelled on the documented value" do
      expect(described_class.new("status" => "cancelled")).to be_cancelled
    end

    it "does not claim unpaid for an unrelated status" do
      expect(described_class.new("status" => "cancelled")).not_to be_unpaid
    end
  end

  # Sale was already right: billed, paid and notBilled are all accepted values.
  describe Conexa::Sale do
    it "is billed on the documented value" do
      expect(described_class.new("status" => "billed")).to be_billed
    end

    it "is editable while not billed" do
      expect(described_class.new("status" => "notBilled")).to be_editable
    end
  end

  # The predicates only mean anything if the attribute they read is one the API
  # actually sends. This is the check that would have caught #23.
  describe "the attributes the predicates depend on" do
    {
      "GET /contracts" => %w[isActive endDate],
      "GET /charges" => %w[status],
      "GET /sales" => %w[status]
    }.each do |operation, fields|
      it "#{operation} documents #{fields.join(", ")}" do
        method, path = operation.split(" ")
        documented = PostmanCollection.response_fields(method, path)

        expect(documented).to include(*fields)
      end
    end

    it "no contract response anywhere documents a status field" do
      %w[/contracts /contract/:id].each do |path|
        expect(PostmanCollection.response_fields("GET", path)).not_to include("status")
      end
    end
  end
end
