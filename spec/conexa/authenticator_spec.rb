# frozen_string_literal: true

require "spec_helper"

RSpec.describe Conexa::Client do
  let(:valid_options) do
    {
      secret_key: "test_secret",
      access_key: "test_access",
      client_id: "test_client_123",
      key: "test_key"
    }
  end

  before do
    # Stub Conexa module methods that Client uses as defaults
    allow(Conexa).to receive(:secret_key).and_return("default_secret")
    allow(Conexa).to receive(:access_key).and_return("default_access")
    allow(Conexa).to receive(:default_client_key).and_return("default_key")
  end

  describe "#initialize" do
    context "with valid parameters" do
      it "creates a client with provided values" do
        client = described_class.new(**valid_options)

        expect(client.secret_key).to eq("test_secret")
        expect(client.access_key).to eq("test_access")
        expect(client.client_id).to eq("test_client_123")
      end

      it "uses default values when not provided" do
        allow(Conexa).to receive(:secret_key).and_return("default_secret")
        allow(Conexa).to receive(:access_key).and_return("default_access")
        allow(Conexa).to receive(:default_client_key).and_return("default_key")

        client = described_class.new(client_id: "test_id")

        expect(client.secret_key).to eq("default_secret")
        expect(client.access_key).to eq("default_access")
        expect(client.key).to eq(:default_key)
      end

      it "defaults type to :pdv" do
        client = described_class.new(**valid_options)
        expect(client.type).to eq(:pdv)
      end

      it "defaults default to true" do
        client = described_class.new(**valid_options)
        expect(client.default).to eq(true)
      end

      it "accepts :e_comerce type" do
        client = described_class.new(**valid_options, type: :e_comerce)
        expect(client.type).to eq(:e_comerce)
      end
    end

    context "with invalid parameters" do
      it "raises ParamError when client_id is missing" do
        expect {
          described_class.new(secret_key: "test", access_key: "test")
        }.to raise_error(Conexa::ParamError)
      end

      it "raises ParamError for invalid type" do
        expect {
          described_class.new(**valid_options, type: :invalid_type)
        }.to raise_error(Conexa::ParamError, /Incorrect client type/)
      end
    end
  end

  describe "#to_h" do
    it "returns hash representation of client" do
      allow(Conexa).to receive(:default_client_key).and_return("my_key")
      client = described_class.new(**valid_options, key: "my_key")

      hash = client.to_h

      expect(hash).to eq({
        secret_key: "test_secret",
        access_key: "test_access",
        client_id: "test_client_123",
        key: :my_key
      })
    end
  end

  describe "#default=" do
    it "allows setting default attribute" do
      client = described_class.new(**valid_options)
      client.default = false
      expect(client.default).to eq(false)
    end
  end
end

RSpec.describe Conexa::Authenticator do
  before do
    allow(Conexa).to receive(:secret_key).and_return("default_secret")
    allow(Conexa).to receive(:access_key).and_return("default_access")
    allow(Conexa).to receive(:default_client_key).and_return("test_key")
  end

  let(:client) do
    Conexa::Client.new(
      secret_key: "test_secret",
      access_key: "test_access",
      client_id: "test_client",
      key: "test_key"
    )
  end

  let(:valid_jwt_token) do
    # Create a JWT that expires in the future
    payload = { "exp" => (Time.now + 3600).to_i, "sub" => "test" }
    JWT.encode(payload, nil, "none")
  end

  let(:expired_jwt_token) do
    # Create an expired JWT
    payload = { "exp" => (Time.now - 3600).to_i, "sub" => "test" }
    JWT.encode(payload, nil, "none")
  end

  # Use a hash-like object that responds to []
  let(:auth_response) do
    { "access_token" => valid_jwt_token, "refresh_token" => "refresh_token_123" }
  end

  describe "#initialize" do
    it "sets client and key" do
      auth_request = instance_double(Conexa::Request)
      allow(Conexa::Request).to receive(:auth).and_return(auth_request)
      allow(auth_request).to receive(:run).and_return(auth_response)

      authenticator = described_class.new(client)

      expect(authenticator.client).to eq(client)
      expect(authenticator.key).to eq(:test_key)
    end

    it "calls authenticate on initialization" do
      auth_request = instance_double(Conexa::Request)
      expect(Conexa::Request).to receive(:auth).with(
        "/pdvauth",
        hash_including(:params)
      ).and_return(auth_request)
      expect(auth_request).to receive(:run).and_return(auth_response)

      described_class.new(client)
    end
  end

  describe "#token" do
    let(:authenticator) do
      auth_request = instance_double(Conexa::Request)
      allow(Conexa::Request).to receive(:auth).and_return(auth_request)
      allow(auth_request).to receive(:run).and_return(auth_response)
      described_class.new(client)
    end

    context "when token is not expired" do
      it "returns the current access token" do
        expect(authenticator.token).to eq(valid_jwt_token)
      end

      it "does not refresh the token" do
        expect(Conexa::Request).not_to receive(:auth).with("/refresh-token", anything)
        authenticator.token
      end
    end

    context "when token is expired" do
      let(:new_valid_token) do
        payload = { "exp" => (Time.now + 7200).to_i, "sub" => "refreshed" }
        JWT.encode(payload, nil, "none")
      end

      let(:refresh_response) do
        { "access_token" => new_valid_token, "refresh_token" => "new_refresh_token" }
      end

      it "refreshes the token before returning" do
        # First, set up with expired token
        expired_auth_response = {
          "access_token" => expired_jwt_token,
          "refresh_token" => "refresh_token_123"
        }

        auth_request = instance_double(Conexa::Request)
        refresh_request = instance_double(Conexa::Request)

        allow(Conexa::Request).to receive(:auth).with("/pdvauth", anything).and_return(auth_request)
        allow(auth_request).to receive(:run).and_return(expired_auth_response)

        authenticator = described_class.new(client)

        # Now expect refresh to be called
        allow(Conexa::Request).to receive(:auth).with("/refresh-token", anything).and_return(refresh_request)
        allow(refresh_request).to receive(:run).and_return(refresh_response)

        expect(authenticator.token).to eq(new_valid_token)
      end
    end
  end
end
