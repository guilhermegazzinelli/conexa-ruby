# frozen_string_literal: true

require "spec_helper"

# The API validates `page` (page=0 -> 400 "Page is too small") and then ignores
# it, always answering with offset 0:
#
#   limit=5&page=1    -> [139, 152, 155, 281, 282]   offset 0
#   limit=5&page=2    -> [139, 152, 155, 281, 282]   offset 0   <- identical
#   limit=5&offset=5  -> [284, 286, 289, 291, 292]   offset 5   <- advances
#
# A loop driven by hasNext therefore never terminates and re-yields the same
# batch, which looks exactly like real data. The gem used to emit a deprecation
# warning and send `page` anyway; it now converts to limit/offset so existing
# callers are quietly fixed rather than loudly broken.
RSpec.describe "legacy page/size pagination" do
  let(:base) { "https://test.conexa.app/index.php/api/v2" }
  let(:list_body) do
    { data: [], pagination: { limit: 5, offset: 0, hasNext: false } }.to_json
  end

  def query_for(&block)
    sent = capture_requests(body: list_body, &block).last
    URI.decode_www_form(sent.uri.query.to_s).to_h
  end

  describe "conversion" do
    it "turns page/size into limit/offset" do
      query = nil
      expect { query = query_for { Conexa::Contract.all(page: 2, size: 5) } }
        .to output(/limit/).to_stderr

      expect(query).to include("limit" => "5", "offset" => "5")
    end

    it "never puts page or size on the wire" do
      query = nil
      expect { query = query_for { Conexa::Contract.all(page: 3, size: 10) } }
        .to output(/DEPRECATION/).to_stderr

      expect(query.keys).not_to include("page", "size")
    end

    it "treats page 1 as offset 0" do
      query = nil
      expect { query = query_for { Conexa::Contract.all(page: 1, size: 25) } }.to output.to_stderr

      expect(query).to include("limit" => "25", "offset" => "0")
    end

    it "defaults size to 100 when only page is given" do
      query = nil
      expect { query = query_for { Conexa::Contract.all(page: 2) } }.to output.to_stderr

      expect(query).to include("limit" => "100", "offset" => "100")
    end

    it "preserves the caller's other filters" do
      query = nil
      expect { query = query_for { Conexa::Charge.all(page: 2, size: 5, status: "pending") } }
        .to output.to_stderr

      expect(query).to include("status" => "pending", "limit" => "5", "offset" => "5")
    end

    it "converts a positional page argument too" do
      query = nil
      expect { query = query_for { Conexa::Contract.all(2, 5) } }.to output.to_stderr

      expect(query).to include("limit" => "5", "offset" => "5")
    end
  end

  describe "validation" do
    it "rejects page 0" do
      expect { Conexa::Contract.all(page: 0, size: 5) }
        .to raise_error(Conexa::RequestError, /page/)
    end

    it "rejects a negative page" do
      expect { Conexa::Contract.all(page: -1) }.to raise_error(Conexa::RequestError, /page/)
    end

    it "rejects size 0" do
      expect { Conexa::Contract.all(page: 1, size: 0) }
        .to raise_error(Conexa::RequestError, /size/)
    end

    it "rejects a non-integer page" do
      expect { Conexa::Contract.all(page: "2") }.to raise_error(Conexa::RequestError, /page/)
    end
  end

  describe "the modern path is untouched" do
    it "passes limit/offset straight through" do
      query = query_for { Conexa::Contract.all(limit: 5, offset: 10) }

      expect(query).to include("limit" => "5", "offset" => "10")
    end

    it "defaults to limit 100, offset 0" do
      query = query_for { Conexa::Contract.all }

      expect(query).to include("limit" => "100", "offset" => "0")
    end

    it "does not warn" do
      expect { query_for { Conexa::Contract.all(limit: 5) } }.not_to output.to_stderr
    end
  end
end
