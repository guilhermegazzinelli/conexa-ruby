#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Anonymises VCR cassettes that were recorded against a real Conexa tenant.
#
# spec/cassettes/customer.yml was recorded on 2024-10-18 against the production
# tenant checkbits.conexa.app and committed to a public repository: it carried a
# live Bearer token plus ~120 real customers (names, CNPJ/CPF, emails, phones,
# street addresses).
#
# This script rewrites a cassette in place, keeping the exact JSON shape — same
# keys, same types, same nulls, same ids — so the specs keep exercising the same
# structure while the payload becomes synthetic. Replacements are deterministic
# (keyed on customerId), so re-running is idempotent and spec expectations stay
# stable.
#
# Usage:  ruby claude_scripts/sanitize_cassettes/sanitize.rb spec/cassettes/customer.yml

require "yaml"
require "json"

REAL_HOST  = "checkbits.conexa.app"
FAKE_HOST  = "test.conexa.app"
TOKEN_RE   = /\b[0-9a-f]{64}\b/
FAKE_TOKEN = "test_token"

# Fields replaced with synthetic values. City and state are deliberately kept:
# they do not identify anyone on their own once the name, document and street
# are gone, and the specs assert on them.
NAME_KEYS    = %w[name firstName lastName tradeName corporateName pronunciation].freeze
CONTACT_KEYS = %w[cellNumber phoneNumber phone login website].freeze
EMAIL_KEYS   = %w[emailsFinancialMessages emailsMessage emails email].freeze
FREE_TEXT    = %w[notes notesNfse observations profession fieldOfActivity].freeze
ADDRESS_KEYS = %w[street number neighborhood additionalDetails zipCode complement].freeze

SUFFIXES = ["LTDA", "ME", "EIRELI", "S.A.", "COMERCIO LTDA"].freeze
BRANDS   = %w[ACME ORION VERTEX LUMEN NIMBUS QUASAR ZENITE ATLAS PRISMA CEDRO
              AURORA BOREAL CANOPUS DELTA EMBER FLORA GRANITO HORIZONTE].freeze

# Deterministic pseudo-identity derived from an integer seed.
class Identity
  def initialize(seed)
    @seed = seed.to_i.abs
  end

  def company = "#{BRANDS[@seed % BRANDS.size]} #{SUFFIXES[@seed % SUFFIXES.size]}"
  def brand   = BRANDS[@seed % BRANDS.size]
  def person  = "Cliente Exemplo #{@seed}"
  def email   = "cliente#{@seed}@example.com"
  def phone   = format("719%08d", @seed % 100_000_000)
  def street  = "Rua Exemplo #{@seed}"
  def number  = (@seed % 900 + 100).to_s
  def zip     = format("41%06d", @seed % 1_000_000)

  # Format-valid but synthetic; the check digits are not meaningful.
  def cnpj = format("%02d.%03d.%03d/0001-%02d",
                    @seed % 90 + 10, @seed % 900 + 100, @seed % 900 + 100, @seed % 90 + 10)
  def cpf  = format("%03d.%03d.%03d-%02d",
                    @seed % 900 + 100, @seed % 900 + 100, @seed % 900 + 100, @seed % 90 + 10)
end

# Sub-objects that are reference data, not personal data — left untouched so
# specs can keep asserting on them (address.state.name / .abbreviation).
REFERENCE_OBJECTS = %w[state country taxDeductions].freeze

def sanitize_record(node, identity, in_address: false)
  return node unless node.is_a?(Hash)

  node.each do |key, value|
    next if value.nil?
    next if REFERENCE_OBJECTS.include?(key)

    case
    when value.is_a?(Hash)
      sanitize_record(value, identity, in_address: in_address || key == "address")
    when value.is_a?(Array) && EMAIL_KEYS.include?(key)
      node[key] = value.each_with_index.map { |_, i| "cliente#{identity.instance_variable_get(:@seed)}+#{i}@example.com" }
    when value.is_a?(Array)
      value.each { |v| sanitize_record(v, identity, in_address: in_address) }
    when in_address && ADDRESS_KEYS.include?(key)
      node[key] = case key
                  when "street"    then identity.street
                  when "number"    then value == "S/N" ? "S/N" : identity.number
                  when "zipCode"   then identity.zip
                  else "Exemplo #{identity.number}"
                  end
    when NAME_KEYS.include?(key)
      node[key] = if key == "firstName" || key == "tradeName" then identity.brand
                  elsif node["isJuridicalPerson"] == false then identity.person
                  else identity.company
                  end
    when CONTACT_KEYS.include?(key)
      node[key] = key == "website" ? "https://example.com" : identity.phone
    when EMAIL_KEYS.include?(key)
      node[key] = identity.email
    when FREE_TEXT.include?(key)
      node[key] = "Texto de exemplo"
    when key == "cnpj" then node[key] = identity.cnpj
    when key == "cpf"  then node[key] = identity.cpf
    end
  end
  node
end

def sanitize_body(json)
  parsed = JSON.parse(json)
  records = parsed.is_a?(Hash) && parsed["data"].is_a?(Array) ? parsed["data"] : [parsed]
  records.each_with_index do |record, i|
    seed = record.is_a?(Hash) ? (record["customerId"] || record["id"] || i) : i
    sanitize_record(record, Identity.new(seed))
  end
  JSON.generate(parsed)
rescue JSON::ParserError
  json
end

path = ARGV[0] or abort "usage: sanitize.rb <cassette.yml>"
cassette = YAML.unsafe_load_file(path)

cassette["http_interactions"].each do |interaction|
  interaction["request"]["uri"] = interaction["request"]["uri"].to_s.gsub(REAL_HOST, FAKE_HOST)

  [interaction["request"], interaction["response"]].each do |half|
    half["headers"]&.each_value do |values|
      values.map! { |v| v.to_s.gsub(TOKEN_RE, FAKE_TOKEN).gsub(REAL_HOST, FAKE_HOST) }
    end
  end

  body = interaction["response"].dig("body", "string")
  interaction["response"]["body"]["string"] = sanitize_body(body) if body
end

File.write(path, cassette.to_yaml)
puts "sanitised #{path} (#{cassette['http_interactions'].size} interactions)"
