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
          ops << [request["method"].to_s.upcase, "/#{Array(request.dig("url", "path")).join("/")}"]
        end
        ops.freeze
      end
    end

    def documented?(method, path)
      operations.include?([method.to_s.upcase, path])
    end

    # @return [Array<String>] the verbs documented for a path, for error messages
    def methods_for(path)
      operations.select { |(_, p)| p == path }.map(&:first).sort
    end

    private

    # Collection items nest arbitrarily deep; leaves are the ones with a "request".
    def each_leaf(items, &block)
      Array(items).each { |item| item["item"] ? each_leaf(item["item"], &block) : block.call(item) }
    end
  end
end
