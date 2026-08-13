# frozen_string_literal: true

require "json"
require "set"

# Reads docs/postman-collection.json — Conexa's published API v2 documentation,
# vendored in this repo — and answers "is this verb + path documented?".
#
# It is the only complete field-level reference for the API: request bodies,
# required/optional flags, conditional requirements and example error responses
# appear nowhere else. When the gem and the collection disagree, the collection
# has been right every time.
#
# Refresh with:
#   curl -s 'https://documenter.gw.postman.com/api/collections/25182821/2s93RZMpcB?segregateAuth=true&versionTag=latest' \
#     > docs/postman-collection.json
module PostmanCollection
  PATH = File.expand_path("../../docs/postman-collection.json", __dir__)

  class << self
    # @return [Set<Array(String, String)>] every documented ["GET", "/customers"]
    def operations
      @operations ||= begin
        raise "missing #{PATH}" unless File.exist?(PATH)

        ops = Set.new
        each_leaf(JSON.parse(File.read(PATH))["item"]) do |leaf|
          request = leaf["request"] or next
          ops << [request["method"].to_s.upcase, path_of(request)]
        end
        raise "#{PATH} yielded no operations — the export format probably changed" if ops.empty?

        ops.freeze
      end
    end

    def documented?(method, path)
      operations.include?([method.to_s.upcase, path])
    end

    # Every field name appearing in any successful response example for an
    # operation, unwrapping the `data` envelope.
    #
    # Deliberately a union across examples, never an exact set. The collection
    # under-documents responses — the live API returns `isActive` on
    # `GET /contract/:id` and no export shows it — so "this response has exactly
    # these fields" would report real fields as missing. "The gem models a field
    # that appears nowhere" is the claim worth testing, and it is what issue #23
    # turned out to be.
    #
    # @return [Array<String>]
    def response_fields(method, path)
      key = [method.to_s.upcase, path]
      @response_fields ||= {}
      @response_fields[key] ||= collect_response_fields(key)
    end

    # @return [Array<String>] the verbs documented for a path, for error messages
    def methods_for(path)
      operations.select { |(_, p)| p == path }.map(&:first).sort
    end

    private

    def collect_response_fields(key)
      fields = []

      each_leaf(JSON.parse(File.read(PATH))["item"]) do |leaf|
        request = leaf["request"] or next
        next unless [request["method"].to_s.upcase, path_of(request)] == key

        Array(leaf["response"]).each do |example|
          next unless example["code"].to_i.between?(200, 299)

          fields |= field_names(example["body"])
        end
      end

      fields
    end

    def field_names(body)
      decoded = begin
        JSON.parse(body.to_s)
      rescue JSON::ParserError
        nil
      end
      return [] unless decoded.is_a?(Hash)

      # `decoded["data"] || decoded` would fall through to the envelope when
      # `data` is present but null, reporting "data"/"pagination" as if they
      # were resource fields. Dormant today — no example is shaped that way —
      # but a refresh could add one.
      rows = if decoded.key?("data")
               Array(decoded["data"])
             else
               [decoded]
             end

      rows.flat_map { |row| row.is_a?(Hash) ? row.keys : [] }.uniq
    end

    # The export has used two shapes for `url`: a Hash carrying a `path` array,
    # and a plain String with the full URL. Normalise both to the path after
    # /api/v2, so refreshing the collection does not silently change what every
    # comparison in the contract spec is comparing.
    def path_of(request)
      url = request["url"]
      raw = url.is_a?(Hash) ? "/#{Array(url["path"]).join("/")}" : url.to_s
      raw = raw.split("?").first.to_s

      marker = "/api/v2"
      index = raw.index(marker)
      raw = raw[(index + marker.length)..] if index

      raw.start_with?("/") ? raw : "/#{raw}"
    end

    # Collection items nest arbitrarily deep; leaves are the ones with a "request".
    def each_leaf(items, &block)
      Array(items).each { |item| item["item"] ? each_leaf(item["item"], &block) : block.call(item) }
    end
  end
end
