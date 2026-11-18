# frozen_string_literal: true

require "spec_helper"

# The API v2 renamed several listing filters and answers 400 to the old names.
# These specs assert on the query string that is really sent.
RSpec.describe "Listing filter aliases (issue #29)" do
  let(:api_host) { "https://test.conexa.app" }
  let(:api_base) { "#{api_host}/index.php/api/v2" }
  let(:empty_body) { { data: [], pagination: { limit: 100, offset: 0, hasNext: false } }.to_json }

  around(:each) do |example|
    VCR.turned_off do
      WebMock.enable!
      example.run
    end
  end

  before(:each) do
    Conexa.configure do |c|
      c.api_token = "test_token"
      c.api_host = api_host
    end
  end

  def json_response(body)
    { status: 200, body: body, headers: { "Content-Type" => "application/json" } }
  end

  def url_for(path)
    /\A#{Regexp.escape("#{api_base}#{path}")}(\?.*)?\z/
  end

  # Runs the block and returns the decoded query pairs of the one request sent.
  def sent_query(path, method: :get, &block)
    stub = stub_request(method, url_for(path))
           .to_return(json_response(empty_body))
    block.call
    expect(stub).to have_been_requested.once
    query = nil
    expect(a_request(method, url_for(path)).with { |req| query = req.uri.query.to_s }).to have_been_made
    URI.decode_www_form(query)
  end

  def quietly
    original = $stderr
    $stderr = StringIO.new
    yield
  ensure
    $stderr = original
  end

  describe "Charge" do
    it "renames the due/payment date filters (symbol keys)" do
      query = quietly do
        sent_query("/charges") do
          Conexa::Charge.all(start_due_date: "2026-01-01", end_due_date: "2026-01-31",
                             start_payment_date: "2026-02-01", end_payment_date: "2026-02-28")
        end
      end

      expect(query).to include(%w[dueDateFrom 2026-01-01], %w[dueDateTo 2026-01-31],
                               %w[paymentDateFrom 2026-02-01], %w[paymentDateTo 2026-02-28])
      names = query.map(&:first)
      expect(names).not_to include("startDueDate", "endDueDate", "startPaymentDate", "endPaymentDate")
    end

    it "accepts string keys" do
      query = quietly do
        sent_query("/charges") do
          Conexa::Charge.where("start_due_date" => "2026-01-01", "end_due_date" => "2026-01-31")
        end
      end

      expect(query).to include(%w[dueDateFrom 2026-01-01], %w[dueDateTo 2026-01-31])
      expect(query.map(&:first)).not_to include("startDueDate", "endDueDate")
    end

    it "covers find_by as well" do
      query = quietly do
        sent_query("/charges") { Conexa::Charge.find_by({ start_due_date: "2026-01-01" }) }
      end

      expect(query).to include(%w[dueDateFrom 2026-01-01])
    end

    it "keeps the new name when both are given, without a colliding key" do
      query = quietly do
        sent_query("/charges") do
          Conexa::Charge.all(start_due_date: "2020-01-01", due_date_from: "2026-01-01",
                             "end_due_date" => "2020-12-31", "due_date_to" => "2026-12-31")
        end
      end

      expect(query.select { |k, _| k == "dueDateFrom" }).to eq([%w[dueDateFrom 2026-01-01]])
      expect(query.select { |k, _| k == "dueDateTo" }).to eq([%w[dueDateTo 2026-12-31]])
    end

    it "does not touch the new names when used alone, and does not warn" do
      query = nil
      expect do
        query = sent_query("/charges") { Conexa::Charge.all(due_date_from: "2026-01-01") }
      end.not_to output.to_stderr

      expect(query).to include(%w[dueDateFrom 2026-01-01])
    end

    it "does not count a nil legacy key as a value" do
      query = nil
      expect do
        query = sent_query("/charges") do
          Conexa::Charge.all(start_due_date: nil, due_date_from: "2026-01-01")
        end
      end.not_to output.to_stderr

      expect(query).to include(%w[dueDateFrom 2026-01-01])
      expect(query.map(&:first)).not_to include("startDueDate")
    end

    it "does not let a nil new name hide the legacy value" do
      query = quietly do
        sent_query("/charges") { Conexa::Charge.all(start_due_date: "2026-01-01", due_date_from: nil) }
      end

      expect(query).to include(%w[dueDateFrom 2026-01-01])
    end

    it "warns once, naming the 0.3.0 removal" do
      stub_request(:get, url_for("/charges"))
        .to_return(json_response(empty_body))

      expect do
        Conexa::Charge.all(start_due_date: "2026-01-01")
        Conexa::Charge.all(start_due_date: "2026-02-01")
      end.to output(/DEPRECATION WARNING.*start_due_date.*due_date_from.*0\.3\.0/m).to_stderr

      expect { Conexa::Charge.all(start_due_date: "2026-03-01") }.not_to output.to_stderr
    end
  end

  describe "Sale" do
    it "renames start_date/end_date to date_from/date_to" do
      query = quietly do
        sent_query("/sales") { Conexa::Sale.all(start_date: "2026-01-01", "end_date" => "2026-01-31") }
      end

      expect(query).to include(%w[dateFrom 2026-01-01], %w[dateTo 2026-01-31])
      expect(query.map(&:first)).not_to include("startDate", "endDate")
    end

    it "prefers the new name" do
      query = quietly do
        sent_query("/sales") { Conexa::Sale.where(start_date: "2020-01-01", date_from: "2026-01-01") }
      end

      expect(query.select { |k, _| k == "dateFrom" }).to eq([%w[dateFrom 2026-01-01]])
    end
  end

  describe "Customer" do
    it "renames ids to id" do
      query = quietly { sent_query("/customers") { Conexa::Customer.all(ids: [1, 2]) } }

      expect(query).to include(["id[]", "1"], ["id[]", "2"])
      expect(query.map(&:first)).not_to include("ids[]", "ids")
    end

    it "accepts the string key and lets id win" do
      query = quietly do
        sent_query("/customers") { Conexa::Customer.all("ids" => [9], id: [1]) }
      end

      expect(query).to include(["id[]", "1"])
      expect(query).not_to include(["id[]", "9"])
    end
  end

  describe "positional hashes and unusual callers" do
    it "translates a positional hash in all/where/find_by" do
      expect(quietly { sent_query("/charges") { Conexa::Charge.all({ start_due_date: "2026-01-01" }) } })
        .to include(%w[dueDateFrom 2026-01-01])
      WebMock.reset!
      expect(quietly { sent_query("/sales") { Conexa::Sale.where({ start_date: "2026-01-01" }) } })
        .to include(%w[dateFrom 2026-01-01])
      WebMock.reset!
      expect(quietly { sent_query("/customers") { Conexa::Customer.all({ "ids" => [1] }) } })
        .to include(["id[]", "1"])
      WebMock.reset!
      expect(quietly { sent_query("/charges") { Conexa::Charge.find_by({}, { start_due_date: "2026-01-01" }) } })
        .to include(%w[dueDateFrom 2026-01-01])
    end

    it "lets the new name win across a positional hash and keywords" do
      query = quietly do
        sent_query("/charges") do
          Conexa::Charge.all({ due_date_from: "NEW" }, start_due_date: "OLD")
        end
      end

      expect(query.select { |k, _| k == "dueDateFrom" }).to eq([%w[dueDateFrom NEW]])
      expect(query.flatten).not_to include("OLD")
    end

    it "accepts nil params like main does" do
      [Conexa::Charge, Conexa::Sale, Conexa::Customer].each do |klass|
        WebMock.reset!
        expect { sent_query(klass.url) { klass.find_by(nil) } }.not_to raise_error
      end
    end

    it "accepts an object that responds to to_hash" do
      holder = Class.new { def to_hash = { start_due_date: "2026-01-01" } }.new

      query = quietly { sent_query("/charges") { Conexa::Charge.find_by(holder) } }

      expect(query).to include(%w[dueDateFrom 2026-01-01])
    end

    it "does not mutate the caller's hash, even a frozen one" do
      params = { start_due_date: "2026-01-01", "ids" => [1] }.freeze
      renames = { start_due_date: :due_date_from, ids: :id }

      result = Conexa::Util.normalize_list_params(params, renames, resource: "Charge", arrays: [:id])

      expect(result).to eq({ due_date_from: "2026-01-01", id: [1] })
      expect(params).to eq({ start_due_date: "2026-01-01", "ids" => [1] })
    end

    it "sends no filter for a lone nil legacy key" do
      query = nil
      expect { query = sent_query("/charges") { Conexa::Charge.all(start_due_date: nil) } }
        .not_to output.to_stderr

      expect(query.map(&:first)).to contain_exactly("limit", "offset")
    end
  end

  describe "camelCase and [] spellings" do
    it "lets a camelCase new name win over a legacy one" do
      query = quietly do
        sent_query("/charges") { Conexa::Charge.all(dueDateFrom: "NEW", start_due_date: "OLD") }
      end
      expect(query.select { |k, _| k == "dueDateFrom" }).to eq([%w[dueDateFrom NEW]])

      WebMock.reset!
      query = quietly do
        sent_query("/sales") { Conexa::Sale.all("dateFrom" => "NEW", start_date: "OLD") }
      end
      expect(query.select { |k, _| k == "dateFrom" }).to eq([%w[dateFrom NEW]])
    end

    it "translates a camelCase legacy name, with a warning" do
      stub_request(:get, url_for("/charges")).to_return(json_response(empty_body))

      expect { Conexa::Charge.all(startDueDate: "2026-01-01") }
        .to output(/start_due_date.*due_date_from/m).to_stderr
    end

    it "translates ids[] and does not merge it with id[]" do
      query = quietly { sent_query("/customers") { Conexa::Customer.all("ids[]": [1, 2]) } }
      expect(query).to include(["id[]", "1"], ["id[]", "2"])
      expect(query.map(&:first)).not_to include("ids[]")

      WebMock.reset!
      query = quietly { sent_query("/customers") { Conexa::Customer.all("id[]": [1], ids: [2]) } }
      expect(query.select { |k, _| k == "id[]" }).to eq([["id[]", "1"]])
    end

    it "joins the spellings of the same array filter, as before" do
      query = quietly { sent_query("/customers") { Conexa::Customer.all(id: [1], "id[]": [2]) } }

      expect(query.select { |k, _| k == "id[]" }).to eq([["id[]", "1"], ["id[]", "2"]])
    end

    it "joins two legacy spellings" do
      query = quietly { sent_query("/customers") { Conexa::Customer.all(ids: [1], "ids[]": [2]) } }

      expect(query.select { |k, _| k == "id[]" }).to eq([["id[]", "1"], ["id[]", "2"]])
    end

    it "treats an empty array as no value" do
      query = quietly { sent_query("/customers") { Conexa::Customer.all(ids: []) } }
      expect(query.map(&:first)).to contain_exactly("limit", "offset")

      WebMock.reset!
      query = quietly { sent_query("/customers") { Conexa::Customer.all(id: [], ids: [2]) } }
      expect(query.select { |k, _| k == "id[]" }).to eq([["id[]", "2"]])
    end

    it "always sends the ids alias as an array" do
      query = quietly { sent_query("/customers") { Conexa::Customer.all(ids: 5) } }

      expect(query).to include(["id[]", "5"])
      expect(query.map(&:first)).not_to include("id")
    end

    it "does not force date filters into arrays" do
      query = quietly { sent_query("/charges") { Conexa::Charge.all(start_due_date: "2026-01-01") } }

      expect(query).to include(%w[dueDateFrom 2026-01-01])
    end
  end

  describe "resources that must not be affected" do
    it "leaves Contract listings untouched (the API rejects both startDate and dateFrom)" do
      query = sent_query("/contracts") { Conexa::Contract.all(start_date: "2026-01-01") }

      expect(query).to include(%w[startDate 2026-01-01])
      expect(query.map(&:first)).not_to include("dateFrom")
    end

    it "leaves RecurringSale listings untouched" do
      query = sent_query("/recurringSales") { Conexa::RecurringSale.all(start_date: "2026-01-01") }

      expect(query).to include(%w[startDate 2026-01-01])
    end

    it "does not emit a deprecation warning for them" do
      stub_request(:get, url_for("/contracts"))
        .to_return(json_response(empty_body))

      expect { Conexa::Contract.all(start_date: "2026-01-01") }.not_to output.to_stderr
    end
  end

  describe "writes are not affected" do
    def body_of(request)
      JSON.parse(request.body)
    end

    it "keeps start_date in a Sale create payload" do
      stub = stub_request(:post, "#{api_base}/sale")
             .to_return(json_response({ id: 1 }.to_json))
      stub_request(:get, "#{api_base}/sale/1")
        .to_return(json_response({ saleId: 1 }.to_json))

      expect do
        Conexa::Sale.new(customer_id: 1, start_date: "2026-01-01", end_date: "2026-02-01").create
      end.not_to output.to_stderr

      expect(stub.with do |req|
        b = body_of(req)
        b["startDate"] == "2026-01-01" && b["endDate"] == "2026-02-01"
      end)
        .to have_been_requested
    end

    it "keeps start_date in a Contract create payload" do
      stub = stub_request(:post, "#{api_base}/contract")
             .to_return(json_response({ id: 1 }.to_json))
      stub_request(:get, "#{api_base}/contract/1")
        .to_return(json_response({ contractId: 1 }.to_json))

      expect do
        Conexa::Contract.new(customer_id: 1, start_date: "2026-01-01").create
      end.not_to output.to_stderr

      expect(stub.with { |req| body_of(req)["startDate"] == "2026-01-01" }).to have_been_requested
    end

    it "does not translate find/show params" do
      stub = stub_request(:get, %r{#{api_base}/sale/1}).with(query: { "startDate" => "x" })
                                                       .to_return(json_response({ saleId: 1 }.to_json))

      expect { Conexa::Sale.find(1, start_date: "x") }.not_to output.to_stderr
      expect(stub).to have_been_requested
    end
  end
end
