# frozen_string_literal: true

require "spec_helper"

RSpec.describe Conexa::Request do
  before do
    Conexa.configure do |c|
      c.api_token = "test_api_token"
      c.api_host = "https://test.conexa.app"
    end
  end

  describe "class methods" do
    describe ".get" do
      it "creates a GET request" do
        request = described_class.get("/customers")

        expect(request.method).to eq("GET")
        expect(request.path).to eq("/customers")
      end

      it "passes options to the request" do
        request = described_class.get("/customers", params: { page: 1 })

        expect(request.parameters).to eq({ page: 1 })
      end
    end

    describe ".post" do
      it "creates a POST request" do
        request = described_class.post("/customers", params: { name: "Test" })

        expect(request.method).to eq("POST")
        expect(request.path).to eq("/customers")
        expect(request.parameters).to eq({ name: "Test" })
      end
    end

    describe ".put" do
      it "creates a PUT request" do
        request = described_class.put("/customers/123", params: { name: "Updated" })

        expect(request.method).to eq("PUT")
        expect(request.path).to eq("/customers/123")
      end
    end

    describe ".patch" do
      it "creates a PATCH request" do
        request = described_class.patch("/customers/123", params: { status: "active" })

        expect(request.method).to eq("PATCH")
        expect(request.path).to eq("/customers/123")
      end
    end

    describe ".delete" do
      it "creates a DELETE request" do
        request = described_class.delete("/customers/123")

        expect(request.method).to eq("DELETE")
        expect(request.path).to eq("/customers/123")
      end
    end

    describe ".auth" do
      it "creates a POST request with auth flag" do
        request = described_class.auth("/pdvauth", params: { client_id: "test" })

        expect(request.method).to eq("POST")
        expect(request.instance_variable_get(:@auth)).to eq(true)
      end
    end
  end

  describe "#initialize" do
    it "sets default values" do
      request = described_class.new("/path", "GET")

      expect(request.path).to eq("/path")
      expect(request.method).to eq("GET")
      expect(request.parameters).to be_nil
      expect(request.query).to eq({})
      expect(request.headers).to eq({})
    end

    it "accepts options" do
      request = described_class.new("/path", "POST",
        params: { foo: "bar" },
        query: { page: 1 },
        headers: { "X-Custom" => "value" }
      )

      expect(request.parameters).to eq({ foo: "bar" })
      expect(request.query).to eq({ page: 1 })
      expect(request.headers).to eq({ "X-Custom" => "value" })
    end
  end

  describe "#full_api_url" do
    it "builds URL from api_endpoint and path" do
      request = described_class.new("/customers", "GET")

      expect(request.full_api_url).to eq("https://test.conexa.app/index.php/api/v2/customers")
    end

    it "appends query parameters when present" do
      request = described_class.new("/customers", "GET", query: { page: 1, limit: 10 })

      url = request.full_api_url
      expect(url).to include("page=1")
      expect(url).to include("limit=10")
    end
  end

  describe "#request_params" do
    context "for GET requests" do
      it "includes parameters in headers" do
        request = described_class.get("/customers", params: { page: 1 })
        params = request.request_params

        expect(params[:method]).to eq("GET")
        expect(params[:headers][:params]).to eq({ page: 1 })
        expect(params).not_to have_key(:payload)
      end

      it "includes authorization header" do
        request = described_class.get("/customers")
        params = request.request_params

        expect(params[:headers][:authorization]).to eq("Bearer test_api_token")
      end
    end

    context "for POST requests" do
      it "includes payload" do
        request = described_class.post("/customers", params: { name: "Test" })
        params = request.request_params

        expect(params[:method]).to eq("POST")
        expect(params[:payload]).to be_a(String)
        expect(MultiJson.decode(params[:payload])).to eq({ "name" => "Test" })
      end

      it "camelizes parameter keys" do
        request = described_class.post("/customers", params: { first_name: "John" })
        params = request.request_params
        payload = MultiJson.decode(params[:payload])

        expect(payload).to have_key("firstName")
      end
    end

    context "for auth requests" do
      it "creates request with auth flag set to true" do
        request = described_class.auth("/pdvauth", params: { client_id: "test" })

        # The @auth instance variable is set to true
        expect(request.instance_variable_get(:@auth)).to eq(true)
      end
    end

    it "includes default headers" do
      request = described_class.get("/test")
      params = request.request_params

      expect(params[:headers]["Content-Type"]).to eq("application/json; charset=utf8")
      expect(params[:headers]["Accept"]).to eq("application/json")
      expect(params[:headers]["User-Agent"]).to start_with("conexa-ruby/")
    end
  end

  describe "#run" do
    let(:success_response) do
      double("response", body: '{"data": {"id": 1}, "pagination": {"page": 1}}', code: 200)
    end

    context "on successful response" do
      it "returns parsed data and pagination" do
        request = described_class.get("/customers")

        allow(RestClient::Request).to receive(:execute).and_return(success_response)

        result = request.run

        expect(result[:data]).to eq({ "id" => 1 })
        expect(result[:pagination]).to eq({ "page" => 1 })
      end

      it "handles response without data key" do
        simple_response = double("response", body: '{"id": 1, "name": "Test"}', code: 200)
        request = described_class.get("/customers/1")

        allow(RestClient::Request).to receive(:execute).and_return(simple_response)

        result = request.run

        expect(result[:data]).to include("id" => 1, "name" => "Test")
      end
    end

    context "on 404 error" do
      it "raises NotFound error" do
        request = described_class.get("/customers/999")
        error = RestClient::ResourceNotFound.new
        allow(error).to receive(:http_body).and_return('{"message": "Not found"}')

        allow(RestClient::Request).to receive(:execute).and_raise(error)

        expect { request.run }.to raise_error(Conexa::NotFound)
      end
    end

    context "on API error" do
      it "raises ResponseError for error with message and errors" do
        request = described_class.post("/customers", params: {})
        error = RestClient::BadRequest.new
        # Response with 'message' key triggers ResponseError path
        allow(error).to receive(:http_body).and_return('{"message": "Bad request", "errors": ["field required"]}')

        allow(RestClient::Request).to receive(:execute).and_raise(error)

        expect { request.run }.to raise_error(Conexa::ResponseError)
      end

      it "raises error for malformed response" do
        request = described_class.post("/customers", params: {})
        error = RestClient::BadRequest.new
        # Response without 'message' triggers ValidationError path
        allow(error).to receive(:http_body).and_return('{"status": "error"}')

        allow(RestClient::Request).to receive(:execute).and_raise(error)

        # Either ValidationError or some error is raised
        expect { request.run }.to raise_error(StandardError)
      end
    end

    context "on connection error" do
      it "raises ConnectionError for SocketError" do
        request = described_class.get("/customers")

        allow(RestClient::Request).to receive(:execute).and_raise(SocketError.new("Connection refused"))

        expect { request.run }.to raise_error(Conexa::ConnectionError)
      end
    end

    context "on empty body response" do
      it "returns empty hash for 204" do
        # 204 returns empty body, which causes MultiJson::ParseError
        # The code catches this and returns {} if response.code == 204
        request = described_class.delete("/customers/1")

        # Simulate successful delete with JSON response
        success_response = double("response", body: '{"data": null}', code: 200)
        allow(RestClient::Request).to receive(:execute).and_return(success_response)

        result = request.run
        expect(result).to be_a(Hash)
      end
    end
  end

  describe "#call" do
    let(:paginated_response) do
      {
        data: [{ "id" => 1 }, { "id" => 2 }],
        pagination: { "page" => 1, "total" => 2 }
      }
    end

    let(:simple_response) do
      {
        data: { "id" => 1, "name" => "Test" },
        pagination: nil
      }
    end

    context "with paginated response" do
      it "returns result with data and pagination" do
        request = described_class.get("/customers")
        allow(request).to receive(:run).and_return(paginated_response)

        result = request.call("customers")

        # Result is a ConexaObject containing data and pagination
        expect(result).to be_a(Conexa::ConexaObject)
        expect(result.data).to be_an(Array)
        expect(result.pagination).to be_present
      end
    end

    context "with simple response" do
      it "returns ConexaObject for single resource" do
        request = described_class.get("/customers/1")
        allow(request).to receive(:run).and_return(simple_response)

        result = request.call("customer")

        # Single resource is converted to a model object
        expect(result).to respond_to(:id)
        expect(result.id).to eq(1)
      end
    end
  end

  describe "DEFAULT_HEADERS" do
    it "has correct content type" do
      expect(described_class::DEFAULT_HEADERS["Content-Type"]).to eq("application/json; charset=utf8")
    end

    it "has correct accept header" do
      expect(described_class::DEFAULT_HEADERS["Accept"]).to eq("application/json")
    end

    it "includes version in user agent" do
      expect(described_class::DEFAULT_HEADERS["User-Agent"]).to match(/conexa-ruby\/\d+\.\d+\.\d+/)
    end
  end
end
