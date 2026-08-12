# frozen_string_literal: true

require "spec_helper"

# Third review round. The headline fix of 0.2.0 — "empty response bodies no
# longer raise" — was only true for `Request#run` in isolation and for the three
# action methods that discard their return value. Every resource's generic
# create/save/destroy still fed the resulting nil into ConexaObject#update.
RSpec.describe "review round 3" do
  let(:base) { "https://test.conexa.app/index.php/api/v2" }

  describe "empty bodies through Model's CRUD" do
    # DELETE /sale/:id is documented as "(204) Success" with no body.
    it "destroys against a 204 without raising" do
      stub_request(:delete, "#{base}/sale/188510").to_return(status: 204, body: "")

      expect { Conexa::Sale.destroy(188_510) }.not_to raise_error
    end

    it "saves against an empty 200 without raising" do
      stub_request(:get, "#{base}/sale/188510").to_return(
        status: 200, body: '{"data":{"saleId":188510,"notes":"a"}}',
        headers: { "Content-Type" => "application/json" }
      )
      stub_request(:patch, "#{base}/sale/188510").to_return(status: 200, body: "")

      sale = Conexa::Sale.find(188_510)
      sale.notes = "b"

      expect { sale.save }.not_to raise_error
    end

    it "keeps the local attributes when the server returns no body" do
      stub_request(:get, "#{base}/sale/188510").to_return(
        status: 200, body: '{"data":{"saleId":188510,"notes":"a"}}',
        headers: { "Content-Type" => "application/json" }
      )
      stub_request(:patch, "#{base}/sale/188510").to_return(status: 204, body: "")

      sale = Conexa::Sale.find(188_510)
      sale.save

      expect(sale.sale_id).to eq(188_510)
    end

    it "creates against an empty body without raising NoMethodError" do
      stub_request(:post, "#{base}/sale").to_return(status: 201, body: "")

      expect { Conexa::Sale.create(notes: "x") }.not_to raise_error
    end
  end

  # An error body that decodes to something other than a Hash used to reach
  # `parsed_error['message']` and raise TypeError from inside the handler.
  describe "error bodies that are not objects" do
    it "raises a Conexa error for an array body" do
      stub_request(:get, "#{base}/customer/1").to_return(
        status: 404, body: "[1,2,3]", headers: { "Content-Type" => "application/json" }
      )

      expect { Conexa::Customer.find(1) }.to raise_error(Conexa::ConexaError)
    end

    it "raises a Conexa error for a bare scalar body" do
      stub_request(:get, "#{base}/customer/1").to_return(
        status: 500, body: "123", headers: { "Content-Type" => "application/json" }
      )

      expect { Conexa::Customer.find(1) }.to raise_error(Conexa::ConexaError)
    end
  end

  describe Conexa::Util do
    # `params.key?(:date)` is true for `date: nil`, so the alias was skipped and
    # the explicit nil went out as `"date": null` — losing the value the caller
    # actually supplied, while the warning claimed a rename had happened.
    it "treats a nil date as absent and uses the deprecated alias" do
      result = nil
      expect { result = described_class.normalize_end_date_param(date: nil, end_date: "2026-08-12") }
        .to output(/end_date/).to_stderr

      expect(described_class.camelize_hash(result)).to eq(date: "2026-08-12")
    end

    it "treats a nil string date key the same way" do
      result = nil
      expect { result = described_class.normalize_end_date_param("date" => nil, :end_date => "2026-08-12") }
        .to output(/end_date/).to_stderr

      expect(described_class.camelize_hash(result)).to eq(date: "2026-08-12")
    end

    it "collapses both date spellings into one key" do
      result = described_class.normalize_end_date_param("date" => "2026-08-12")

      expect(described_class.camelize_hash(result)).to eq(date: "2026-08-12")
    end
  end

  describe "read-only mode" do
    after { Conexa.configuration.read_only = false }

    # Request.auth is public and its exemption was keyed off a caller-supplied
    # flag, so any write could opt out of the guard by passing auth: true.
    it "does not let the auth flag exempt a non-auth path" do
      Conexa.configuration.read_only = true

      expect { Conexa::Request.auth("/charge/settle/789", params: { amount: 100 }).run }
        .to raise_error(Conexa::ReadOnlyError)
    end

    it "still exempts the real auth endpoint" do
      Conexa.configuration.read_only = true
      stub_request(:post, "#{base}/auth").to_return(
        status: 200, body: '{"data":{"accessToken":"x"}}',
        headers: { "Content-Type" => "application/json" }
      )

      expect { Conexa::Auth.login(username: "u", password: "p") }.not_to raise_error
    end
  end

  describe "CONEXA_READ_ONLY" do
    around do |example|
      previous = Conexa.configuration.read_only
      example.run
      Conexa.configuration.read_only = previous
    end

    # Was read once in Configuration#initialize, so setting it after
    # Conexa.configure had run was a silent no-op.
    it "is honoured even when set after configure ran" do
      config = Conexa::Configuration.new
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("CONEXA_READ_ONLY").and_return("1")

      expect(config.read_only).to be(true)
    end

    it "lets an explicit setting override the environment" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("CONEXA_READ_ONLY").and_return("1")

      config = Conexa::Configuration.new
      config.read_only = false

      expect(config.read_only).to be(false)
    end

    it "warns instead of failing open on an unrecognised value" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("CONEXA_READ_ONLY").and_return("treu")

      config = Conexa::Configuration.new
      expect { config.read_only }.to output(/CONEXA_READ_ONLY/).to_stderr
    end
  end
end
