#!/usr/bin/env ruby
# frozen_string_literal: true

#
# Asks the live API what it actually returns, instead of inferring it from the
# collection. Reads only — see README.md for why there is no write mode.
#
# Records SHAPE ONLY: status, whether the body is empty, the top-level type, key
# names, counts. Never values. The output is safe to commit and to paste into an
# issue. This repo has already had one incident with a cassette full of real
# customer data; that must not repeat.
#
# Usage:
#   CONEXA_API_HOST=https://yourtenant.conexa.app \
#   CONEXA_API_TOKEN=... \
#   ruby claude_scripts/probe_api_shapes/probe.rb

$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)
require "conexa"
require "multi_json"
require "rest_client"

# The API allows 60 requests per minute and answers 429 beyond that.
THROTTLE = 1.1

# An id chosen to not exist, for probing the not-found shape.
ABSENT_ID = 999_999_999

# list endpoint => the singular path its ids can be read from.
READS = {
  "/customers" => "/customer",
  "/charges" => "/charge",
  "/contracts" => "/contract",
  "/companies" => "/company",
  "/plans" => "/plan",
  "/sales" => "/sale",
  "/persons" => "/person",
  "/products" => "/product",
  "/bills" => "/bill",
  "/recurringSales" => "/recurringSale",
  "/costCenters" => "/costCenter",
  "/paymentMethods" => "/paymentMethod",
  "/receivingMethods" => "/receivingMethod",
  "/invoicingMethods" => "/invoicingMethod",
  "/billCategories" => "/billCategory",
  "/billSubcategories" => "/billSubcategory",
  "/room/bookings" => "/room/booking",
  # Absent from the collection. The 2026-08-12 probe found the first three real
  # and the CreditCard reads missing; re-running tells us if that changed.
  "/accounts" => "/account",
  "/suppliers" => "/supplier",
  "/serviceCategories" => "/serviceCategory",
  "/creditCard" => nil
}.freeze

class Probe
  def initialize
    @host  = fetch_env("CONEXA_API_HOST")
    @token = fetch_env("CONEXA_API_TOKEN")
  end

  def run!
    # The gem's own guard, plus the assertion in #get that nothing but GET is
    # ever issued. Belt and braces: this script talks to production.
    Conexa.configure do |c|
      c.api_host  = @host
      c.api_token = @token
      c.read_only = true
    end

    section "Listings and their envelope"
    READS.each do |list, show|
      shape, decoded = get(list, limit: 3)
      row(list, shape)
      next unless show

      id = first_id(decoded)
      id ? row("#{show}/:id", get("#{show}/#{id}").first) : note("sem id na listagem")
    end

    section "Pagination"
    row("/customers?limit=1&offset=0", get("/customers", limit: 1, offset: 0).first)
    row("/customers?limit=1&offset=1", get("/customers", limit: 1, offset: 1).first)
    # The premise behind converting page/size: the API validates page and then
    # ignores it, always answering offset 0.
    row("/customers?limit=1&page=2", get("/customers", limit: 1, page: 2).first)

    section "Error shapes"
    row("/customer/#{ABSENT_ID}", get("/customer/#{ABSENT_ID}").first)
    row("/rotaInexistente", get("/rotaInexistente").first)
    row("/charges?campoInventado=1", get("/charges", limit: 1, campoInventado: 1).first)

    puts "\nSó formas acima — nenhum valor foi impresso."
  end

  private

  def get(path, **query)
    sleep THROTTLE
    response = RestClient::Request.execute(
      method: :get, url: "#{@host}/index.php/api/v2#{path}",
      headers: { accept: :json, content_type: :json,
                 authorization: "Bearer #{@token}", params: query }
    )
    decode(response)
  rescue RestClient::Exception => e
    decode(e.response, error: e.class.name.split("::").last)
  rescue StandardError => e
    [{ error: e.class.name, note: e.message.to_s[0, 60] }, nil]
  end

  # @return [Array(Hash, Object)] the shape (safe to print) and the decoded body
  #   (kept in memory only, so an id can be reused for the show probe)
  def decode(response, error: nil)
    body = response&.body.to_s
    shape = { status: response&.code, error: error, empty_body: body.strip.empty? }.compact
    return [shape, nil] if shape[:empty_body]

    decoded = begin
      MultiJson.decode(body)
    rescue MultiJson::ParseError
      return [shape.merge(top_level: "unparseable", bytes: body.bytesize), nil]
    end

    [shape.merge(describe(decoded)), decoded]
  end

  def describe(decoded)
    case decoded
    when nil   then { top_level: "null" }
    when Array then { top_level: "Array", count: decoded.size }
    when Hash  then describe_hash(decoded)
    else { top_level: decoded.class.name }
    end
  end

  def describe_hash(hash)
    out = { top_level: "Hash", keys: hash.keys.sort }
    out[:data_type]  = hash["data"].class.name if hash.key?("data")
    out[:data_count] = hash["data"].size if hash["data"].is_a?(Array)
    out[:pagination] = hash["pagination"].keys.sort if hash["pagination"].is_a?(Hash)
    first_error = hash["errors"].first if hash["errors"].is_a?(Array)
    out[:error_keys] = first_error.keys.sort if first_error.is_a?(Hash)
    out
  end

  # Reads an id purely so the show probe does not have to guess one. Used in a
  # URL, never printed.
  def first_id(decoded)
    rows = decoded.is_a?(Hash) ? decoded["data"] : decoded
    first = rows.is_a?(Array) ? rows.first : nil
    return nil unless first.is_a?(Hash)

    key = first.keys.find { |k| k.end_with?("Id") } || "id"
    first[key]
  end

  def section(title) = puts("\n#{"=" * 76}\n #{title}\n#{"=" * 76}")
  def row(label, shape) = puts(format("  %-34s %s", label, shape.inspect))
  def note(text) = puts("  #{" " * 34} (#{text})")

  def fetch_env(name)
    value = ENV[name].to_s
    value.empty? ? abort("faltando #{name}") : value
  end
end

Probe.new.run!
