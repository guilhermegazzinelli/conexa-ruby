# frozen_string_literal: true

require "spec_helper"

# Read-only mode: a hard guard against writing to a tenant you only meant to
# read from.
#
# This gem talks to a billing system — settling a charge moves money and can
# issue an NF-e. A lot of real use is investigation ("was this invoice paid?"),
# and the most common way to cause damage is pointing an otherwise-correct script
# at the wrong tenant. The guard sits at Request#run, the single choke point every
# verb passes through.
RSpec.describe "read-only mode" do
  let(:base) { "https://test.conexa.app/index.php/api/v2" }

  after { Conexa.configuration.read_only = false }

  describe "when enabled globally" do
    before { Conexa.configuration.read_only = true }

    it "allows GET" do
      stub_request(:get, "#{base}/charge/555").to_return(
        status: 200, body: '{"data":{"chargeId":555}}',
        headers: { "Content-Type" => "application/json" }
      )

      expect(Conexa::Charge.find(555).charge_id).to eq(555)
    end

    %w[POST PATCH PUT DELETE].each do |verb|
      it "refuses #{verb}" do
        expect { Conexa::Request.new("/charge/555", verb, params: {}).run }
          .to raise_error(Conexa::ReadOnlyError, /#{verb}.*charge\/555/m)
      end
    end

    it "refuses before the request reaches the network" do
      stub = stub_request(:patch, "#{base}/charge/settle/555")

      expect { Conexa::Request.patch("/charge/settle/555", params: {}).run }
        .to raise_error(Conexa::ReadOnlyError)
      expect(stub).not_to have_been_requested
    end

    it "blocks a settlement attempted through the resource" do
      stub_request(:get, "#{base}/charge/555").to_return(
        status: 200, body: '{"data":{"chargeId":555}}',
        headers: { "Content-Type" => "application/json" }
      )

      expect { Conexa::Charge.settle(555) }.to raise_error(Conexa::ReadOnlyError)
    end

    # Without this exemption you could not obtain a token, which would make
    # read-only mode useless for the username/password flow.
    it "still allows authentication" do
      stub_request(:post, "#{base}/auth").to_return(
        status: 200, body: '{"data":{"accessToken":"abc"}}',
        headers: { "Content-Type" => "application/json" }
      )

      expect { Conexa::Auth.login(username: "u", password: "p") }.not_to raise_error
    end

    it "reports as read_only?" do
      expect(Conexa).to be_read_only
    end
  end

  describe "when disabled" do
    it "allows writes" do
      stub_request(:patch, "#{base}/charge/settle/555").to_return(status: 204, body: "")

      expect { Conexa::Request.patch("/charge/settle/555", params: {}).run }.not_to raise_error
    end

    it "reports as not read_only?" do
      expect(Conexa).not_to be_read_only
    end
  end

  describe "Conexa.read_only with a block" do
    it "applies only inside the block" do
      stub_request(:patch, "#{base}/charge/settle/555").to_return(status: 204, body: "")

      Conexa.read_only do
        expect { Conexa::Request.patch("/charge/settle/555", params: {}).run }
          .to raise_error(Conexa::ReadOnlyError)
      end

      expect { Conexa::Request.patch("/charge/settle/555", params: {}).run }.not_to raise_error
    end

    it "restores the previous state even when the block raises" do
      expect { Conexa.read_only { raise "boom" } }.to raise_error("boom")
      expect(Conexa).not_to be_read_only
    end

    it "returns the block's value" do
      expect(Conexa.read_only { 42 }).to eq(42)
    end

    it "does not leak into another thread" do
      other = nil
      Conexa.read_only { other = Thread.new { Conexa.read_only? }.value }
      expect(other).to be(false)
    end
  end

  describe "CONEXA_READ_ONLY" do
    it "defaults a fresh Configuration to read-only when set" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("CONEXA_READ_ONLY").and_return("1")

      expect(Conexa::Configuration.new.read_only).to be(true)
    end

    it "leaves a fresh Configuration writable when unset" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("CONEXA_READ_ONLY").and_return(nil)

      expect(Conexa::Configuration.new.read_only).to be(false)
    end
  end
end
