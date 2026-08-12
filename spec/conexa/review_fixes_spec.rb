# frozen_string_literal: true

require "spec_helper"

# Cover for the issues raised reviewing PR #21, plus the two open issues that sit
# in the same code paths (#11, #12). All four are the same family as the defects
# this release exists to fix: an exception escaping Conexa::ConexaError, or a
# parameter name that disagrees with the documented contract.
RSpec.describe "review fixes" do
  let(:base) { "https://test.conexa.app/index.php/api/v2" }

  # The verb was fixed for RecurringSale, but the field name was only fixed for
  # Contract — so `end_date:` still went out as `endDate` here and 400'd. The
  # collection documents `date` as required on PATCH /recurringSale/end/:id,
  # exactly as on /contract/end/:id.
  describe Conexa::RecurringSale do
    it "sends the documented date field" do
      sent = capture_request { described_class.end_recurring_sale(42, date: "2026-08-12") }

      expect(sent_payload(sent)).to eq("date" => "2026-08-12")
    end

    it "translates the deprecated end_date: like Contract does" do
      sent = nil
      expect { sent = capture_request { described_class.end_recurring_sale(42, end_date: "2026-08-12") } }
        .to output(/end_date/).to_stderr

      expect(sent_payload(sent)).to eq("date" => "2026-08-12")
    end

    it "does not let end_date: override an explicit date:" do
      sent = capture_request do
        described_class.end_recurring_sale(42, date: "2026-08-12", end_date: "2020-01-01")
      end

      expect(sent_payload(sent)).to eq("date" => "2026-08-12")
    end
  end

  # Issue #11. RestClient::ServerBrokeConnection < RestClient::Exception, so the
  # broad rescue always matched first and the specific one was dead code. Its
  # http_body is nil, and MultiJson.decode(nil) returns nil rather than raising
  # (the same Oj behaviour behind the empty-body defect), so the handler itself
  # blew up with NoMethodError.
  describe "connection failures" do
    def request_raising(error_class, message = "boom")
      request = Conexa::Request.get("/customers")
      request.define_singleton_method(:request_params) { raise error_class, message }
      request
    end

    it "maps a broken connection to ConnectionError" do
      expect { request_raising(RestClient::ServerBrokeConnection).run }
        .to raise_error(Conexa::ConnectionError)
    end

    it "maps a socket error to ConnectionError" do
      expect { request_raising(SocketError).run }.to raise_error(Conexa::ConnectionError)
    end

    it "maps an open timeout to ConnectionError" do
      expect { request_raising(RestClient::Exceptions::OpenTimeout).run }
        .to raise_error(Conexa::ConnectionError)
    end

    it "maps a read timeout to ConnectionError" do
      expect { request_raising(RestClient::Exceptions::ReadTimeout).run }
        .to raise_error(Conexa::ConnectionError)
    end

    it "never lets a raw NoMethodError escape for an error with no body" do
      expect { request_raising(RestClient::ServerBrokeConnection).run }
        .not_to raise_error(NoMethodError)
    end

    # An HTTP error with an empty body is not a connection failure — it should
    # still land in the response taxonomy.
    it "still raises ResponseError for an HTTP error with no body" do
      stub_request(:get, "#{base}/customers").to_return(status: 500, body: "")

      expect { Conexa::Request.get("/customers").run }.to raise_error(Conexa::ConexaError)
    end
  end

  # Issue #12. A stray space produced URI::InvalidURIError from deep inside
  # RestClient — outside the Conexa::ConexaError hierarchy, so no caller could
  # rescue it meaningfully.
  describe "ids that do not belong in a URL" do
    it "tolerates surrounding whitespace" do
      stub_request(:get, "#{base}/customer/123").to_return(
        status: 200, body: '{"data":{"customerId":123}}',
        headers: { "Content-Type" => "application/json" }
      )

      expect(Conexa::Customer.find(" 123 ").customer_id).to eq(123)
    end

    it "raises RequestError, not URI::InvalidURIError, for an unusable id" do
      expect { Conexa::Customer.find("12 3") }.to raise_error(Conexa::RequestError, /path/i)
    end

    it "keeps rejecting a blank id" do
      expect { Conexa::Customer.find("   ") }.to raise_error(Conexa::RequestError, /Invalid ID/)
    end
  end

  # The PR changed primary_key_attribute so #id is no longer an alias; the class
  # documentation still said it was.
  describe Conexa::Model do
    it "resolves #id from the resource's own key" do
      expect(Conexa::Charge.new("charge_id" => 7).id).to eq(7)
    end

    it "falls back to a plain id attribute, which is what write endpoints return" do
      expect(Conexa::Charge.new("id" => 9).id).to eq(9)
    end

    it "prefers the resource's own key when both are present" do
      expect(Conexa::Charge.new("charge_id" => 7, "id" => 9).id).to eq(7)
    end
  end
end
