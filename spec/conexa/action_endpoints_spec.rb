# frozen_string_literal: true

require "spec_helper"

# Asserts the verb and payload the gem actually puts on the wire for the action
# endpoints — the ones where the verb is hand-picked rather than derived by Model.
#
# The API uses PATCH for every action. The gem used POST for three of them, and
# every one 404'd against a live tenant. The existing integration specs did not
# notice because their stubs were written from the implementation; these capture
# the request instead.
RSpec.describe "action endpoints" do
  let(:base) { "https://test.conexa.app/index.php/api/v2" }

  describe Conexa::Charge do
    it "settles with PATCH /charge/settle/:id" do
      sent = capture_request { described_class.settle(555) }

      expect(sent.method).to eq(:patch)
      expect(sent.uri.to_s).to end_with("/charge/settle/555")
    end

    it "passes the documented settlement payload through camelized" do
      sent = capture_request do
        described_class.settle(555,
                               settlement_date: "2026-08-11",
                               receiving_method: { id: 53, installments_quantity: 3 },
                               account_id: 1,
                               send_email: false)
      end

      expect(sent_payload(sent)).to eq(
        "settlementDate"  => "2026-08-11",
        "receivingMethod" => { "id" => 53, "installmentsQuantity" => 3 },
        "accountId"       => 1,
        "sendEmail"       => false
      )
    end

    it "reads the PIX QR code with GET /charge/pix/:id" do
      sent = capture_request { described_class.pix(555) }

      expect(sent.method).to eq(:get)
      expect(sent.uri.to_s).to include("/charge/pix/555")
    end
  end

  describe Conexa::RecurringSale do
    it "ends with PATCH /recurringSale/end/:id" do
      sent = capture_request { described_class.end_recurring_sale(42, date: "2026-08-11") }

      expect(sent.method).to eq(:patch)
      expect(sent.uri.to_s).to end_with("/recurringSale/end/42")
    end
  end

  describe Conexa::Contract do
    it "ends with PATCH /contract/end/:id" do
      sent = capture_request { described_class.end_contract(789, date: "2026-08-11") }

      expect(sent.method).to eq(:patch)
      expect(sent.uri.to_s).to end_with("/contract/end/789")
    end

    it "sends the documented field names" do
      sent = capture_request do
        described_class.end_contract(789, date: "2026-08-11", reason_id: 2, unlink_customer: true)
      end

      expect(sent_payload(sent)).to eq(
        "date" => "2026-08-11", "reasonId" => 2, "unlinkCustomer" => true
      )
    end

    # The old public signature was end_contract(id, end_date:, reason:), which
    # camelized to endDate and 400'd: "endDate field does not exist".
    describe "the deprecated end_date: alias" do
      it "is translated to the documented date:" do
        sent = nil
        expect { sent = capture_request { described_class.end_contract(789, end_date: "2026-08-11") } }
          .to output(/end_date/).to_stderr

        expect(sent_payload(sent)).to eq("date" => "2026-08-11")
      end

      it "does not override an explicit date:" do
        sent = capture_request do
          described_class.end_contract(789, date: "2026-08-11", end_date: "2020-01-01")
        end

        expect(sent_payload(sent)).to eq("date" => "2026-08-11")
      end
    end

    # The endpoint is documented as "encerra um contrato ativo ou atualiza a data
    # de encerramento" — it amends as well as closes, and a future date on a
    # closed contract reopens it.
    it "exposes the same call as set_end_date" do
      sent = capture_request { described_class.find(789).set_end_date(date: "2026-08-11") }

      expect(sent.method).to eq(:patch)
      expect(sent_payload(sent)).to eq("date" => "2026-08-11")
    end
  end

  describe Conexa::RoomBooking do
    it "cancels with PATCH /room/booking/:id/cancel" do
      sent = capture_request { described_class.cancel(143063) }

      expect(sent.method).to eq(:patch)
      expect(sent.uri.to_s).to end_with("/room/booking/143063/cancel")
    end

    it "checks out with POST /room/booking/:id/checkout" do
      sent = capture_request { described_class.checkout(143063) }

      expect(sent.method).to eq(:post)
      expect(sent.uri.to_s).to end_with("/room/booking/143063/checkout")
    end
  end
end
