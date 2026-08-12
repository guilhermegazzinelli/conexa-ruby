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

    # Same shape as ServerBrokeConnection: a direct RestClient::Exception subclass
    # with no response and a nil http_body. A TLS handshake failure is a
    # connection failure, not a validation error.
    it "maps a TLS verification failure to ConnectionError" do
      expect { request_raising(RestClient::SSLCertificateNotVerified).run }
        .to raise_error(Conexa::ConnectionError)
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

    it "validates the URL at the request layer, not just through Model" do
      expect { Conexa::Request.get("/customer/12 3").full_api_url }
        .to raise_error(Conexa::RequestError, /Invalid request path/)
    end

    # Read-only is a policy: it must win regardless of what the path looks like,
    # or a caller rescuing ReadOnlyError to report "you are in read-only mode"
    # gets a misleading "invalid path" instead.
    it "reports read-only mode even when the path is unusable" do
      Conexa.configuration.read_only = true

      expect { Conexa::Request.patch("/customer/12 3", params: {}).run }
        .to raise_error(Conexa::ReadOnlyError)
    ensure
      Conexa.configuration.read_only = false
    end
  end

  # `params[:date] ||=` only sees the symbol key, so a caller passing a string
  # "date" got a second, colliding :date — and camelize_hash folds both into one,
  # last-write-wins, so the deprecated value silently replaced the real one.
  describe Conexa::Util do
    it "does not let a string date key collide with the deprecated alias" do
      result = described_class.normalize_end_date_param("date" => "2026-08-12",
                                                        :end_date => "2020-01-01")

      expect(result.values.uniq).to eq(["2026-08-12"])
      expect(Conexa::Util.camelize_hash(result)).to eq(date: "2026-08-12")
    end

    it "accepts the deprecated alias under a string key" do
      result = nil
      expect { result = described_class.normalize_end_date_param("end_date" => "2026-08-12") }
        .to output(/end_date/).to_stderr

      expect(Conexa::Util.camelize_hash(result)).to eq(date: "2026-08-12")
    end

    it "removes both spellings of the deprecated alias" do
      both = { :end_date => "2026-08-12", "end_date" => "2026-08-12" }
      result = nil

      expect { result = described_class.normalize_end_date_param(both) }
        .to output(/end_date/).to_stderr

      expect(Conexa::Util.camelize_hash(result)).to eq(date: "2026-08-12")
    end

    it "leaves a hash with no end_date untouched" do
      expect(described_class.normalize_end_date_param(date: "2026-08-12", reason_id: 2))
        .to eq(date: "2026-08-12", reason_id: 2)
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
