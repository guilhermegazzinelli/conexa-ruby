# frozen_string_literal: true

require "spec_helper"

RSpec.describe Conexa::TokenManager do
  before(:each) do
    # Reset the singleton instance before each test
    described_class.instance_variable_set(:@instance, nil)

    # Stub Conexa module methods
    allow(Conexa).to receive(:secret_key).and_return("test_secret")
    allow(Conexa).to receive(:access_key).and_return("test_access")
    allow(Conexa).to receive(:client_id).and_return("test_client_id")
    allow(Conexa).to receive(:default_client_key).and_return(:default)
    allow(Conexa).to receive(:credentials).and_return(nil)
  end

  let(:valid_jwt_token) do
    payload = { "exp" => (Time.now + 3600).to_i, "sub" => "test" }
    JWT.encode(payload, nil, "none")
  end

  let(:auth_response) do
    { "access_token" => valid_jwt_token, "refresh_token" => "refresh_token_123" }
  end

  let(:mock_auth_request) do
    request = instance_double(Conexa::Request)
    allow(request).to receive(:run).and_return(auth_response)
    request
  end

  describe ".instance" do
    before do
      allow(Conexa::Request).to receive(:auth).and_return(mock_auth_request)
    end

    it "creates a singleton instance" do
      instance1 = described_class.instance
      instance2 = described_class.instance

      expect(instance1).to be(instance2)
    end

    it "initializes with authenticators" do
      instance = described_class.instance
      expect(instance.authenticators).to be_an(Array)
    end

    it "initializes with a mutex" do
      instance = described_class.instance
      expect(instance.mutex).to be_a(Mutex)
    end
  end

  describe "#initialize" do
    context "when Conexa.credentials is nil" do
      before do
        allow(Conexa::Request).to receive(:auth).and_return(mock_auth_request)
      end

      it "creates default authenticator from Conexa settings" do
        instance = described_class.instance

        expect(instance.authenticators.length).to eq(1)
        expect(instance.authenticators.first.key).to eq(:default)
      end
    end

    context "when Conexa.credentials is an Array" do
      let(:credentials_array) do
        [
          { secret_key: "secret1", access_key: "access1", client_id: "client1", key: :client_one },
          { secret_key: "secret2", access_key: "access2", client_id: "client2", key: :client_two }
        ]
      end

      before do
        allow(Conexa).to receive(:credentials).and_return(credentials_array)
        allow(Conexa::Request).to receive(:auth).and_return(mock_auth_request)
      end

      it "creates authenticators for each credential" do
        instance = described_class.instance

        expect(instance.authenticators.length).to eq(2)
        keys = instance.authenticators.map(&:key)
        expect(keys).to contain_exactly(:client_one, :client_two)
      end
    end
  end

  describe ".token_for" do
    before do
      allow(Conexa::Request).to receive(:auth).and_return(mock_auth_request)
    end

    context "when authenticator exists for key" do
      it "returns the token for the default key" do
        token = described_class.token_for(:default)
        expect(token).to eq(valid_jwt_token)
      end

      it "uses default_client_key when no key provided" do
        token = described_class.token_for
        expect(token).to eq(valid_jwt_token)
      end
    end

    context "when authenticator does not exist for key" do
      it "raises MissingCredentialsError" do
        expect {
          described_class.token_for(:nonexistent_key)
        }.to raise_error(Conexa::MissingCredentialsError, /Missing credentials for key/)
      end
    end
  end

  describe ".add_client" do
    before do
      allow(Conexa::Request).to receive(:auth).and_return(mock_auth_request)
    end

    context "with a new client" do
      let(:new_client) do
        Conexa::Client.new(
          secret_key: "new_secret",
          access_key: "new_access",
          client_id: "new_client_id",
          key: :new_client
        )
      end

      it "adds the client to authenticators" do
        described_class.instance # Initialize first
        initial_count = described_class.instance.authenticators.length

        described_class.add_client(new_client)

        expect(described_class.instance.authenticators.length).to eq(initial_count + 1)
      end

      it "accepts a hash and creates a client" do
        described_class.instance
        initial_count = described_class.instance.authenticators.length

        described_class.add_client(
          secret_key: "hash_secret",
          access_key: "hash_access",
          client_id: "hash_client_id",
          key: :hash_client
        )

        expect(described_class.instance.authenticators.length).to eq(initial_count + 1)
      end
    end

    context "with duplicate key" do
      it "raises ParamError" do
        described_class.instance # Initialize with default client

        duplicate_client = Conexa::Client.new(
          secret_key: "dup_secret",
          access_key: "dup_access",
          client_id: "dup_client_id",
          key: :default # Same as existing
        )

        expect {
          described_class.add_client(duplicate_client)
        }.to raise_error(Conexa::ParamError, /already exists/)
      end
    end
  end

  describe ".client_for" do
    before do
      allow(Conexa::Request).to receive(:auth).and_return(mock_auth_request)
    end

    context "when client exists" do
      it "returns the client for the given key" do
        client = described_class.client_for(:default)

        expect(client).to be_a(Conexa::Client)
        expect(client.key).to eq(:default)
      end
    end

    context "when client does not exist" do
      it "returns nil" do
        client = described_class.client_for(:nonexistent)
        expect(client).to be_nil
      end
    end
  end

  describe ".client_type_for" do
    before do
      allow(Conexa::Request).to receive(:auth).and_return(mock_auth_request)
    end

    context "when client exists" do
      it "returns the client type" do
        type = described_class.client_type_for(:default)
        expect(type).to eq(:pdv)
      end
    end

    context "when client does not exist" do
      it "returns :pdv as default" do
        type = described_class.client_type_for(:nonexistent)
        expect(type).to eq(:pdv)
      end
    end
  end
end
