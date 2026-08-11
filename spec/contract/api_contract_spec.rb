# frozen_string_literal: true

require "spec_helper"

# Asserts the gem against the published API contract, not against itself.
#
# The rest of the suite stubs HTTP with expectations written from the
# implementation, so it cannot see a wrong verb, a wrong URL or a wrong field
# name. This file compares what the gem emits against
# docs/postman-collection.json, which is Conexa's own documentation.
#
# It is the CI form of the sweep that found `Conexa::Company.url == "/companys"`.
RSpec.describe "API v2 contract" do
  # Paths the gem uses that the collection does not document. These are NOT
  # assumed wrong — the collection is incomplete for several read endpoints, and
  # some of these were built from observed production responses. They are
  # unverified, and listing them explicitly is what makes a *new* undocumented
  # path fail this spec instead of slipping through.
  #
  # See .okf/architecture/resource-catalog.md for the per-path rationale.
  UNDOCUMENTED = [
    ["GET",  "/accounts"],             # only GET /account/:id is documented
    ["GET",  "/suppliers"],            # only POST /supplier is documented
    ["GET",  "/supplier/:id"],
    ["GET",  "/serviceCategories"],
    ["GET",  "/serviceCategory/:id"],
    ["GET",  "/creditCard"],           # only POST /creditCard is documented
    ["GET",  "/creditCard/:id"],
    ["POST", "/charge/cancel/:id"],
    ["POST", "/charge/sendEmail/:id"]
  ].freeze

  # Every endpoint a resource reaches with a hand-picked verb and path, i.e.
  # everything Model's CRUD does not derive. This table is the thing that has to
  # stay honest; the last example in this file proves nothing was added without
  # being listed here.
  ACTIONS = [
    { file: "charge.rb",         method: "Charge#settle",                    verb: "PATCH",  path: "/charge/settle/:id" },
    { file: "charge.rb",         method: "Charge#pix",                       verb: "GET",    path: "/charge/pix/:id" },
    { file: "charge.rb",         method: "Charge#cancel",                    verb: "POST",   path: "/charge/cancel/:id" },
    { file: "charge.rb",         method: "Charge#send_email",                verb: "POST",   path: "/charge/sendEmail/:id" },
    { file: "contract.rb",       method: "Contract#end_contract",            verb: "PATCH",  path: "/contract/end/:id" },
    { file: "recurring_sale.rb", method: "RecurringSale#end_recurring_sale", verb: "PATCH",  path: "/recurringSale/end/:id" },
    { file: "room_booking.rb",   method: "RoomBooking#cancel",               verb: "PATCH",  path: "/room/booking/:id/cancel" },
    { file: "room_booking.rb",   method: "RoomBooking#checkout",             verb: "POST",   path: "/room/booking/:id/checkout" },
    { file: "room_booking.rb",   method: "RoomBooking.checkin",              verb: "POST",   path: "/checkin" },
    { file: "room_booking.rb",   method: "RoomBooking.standalone_checkout",  verb: "POST",   path: "/checkout" }
  ].freeze

  def self.model_classes
    Conexa.constants
          .map { |c| Conexa.const_get(c) }
          .select { |c| c.is_a?(Class) && c < Conexa::Model }
          .sort_by(&:name)
  end

  def allowed?(verb, path)
    PostmanCollection.documented?(verb, path) || UNDOCUMENTED.include?([verb, path])
  end

  def explain(verb, path)
    others = PostmanCollection.methods_for(path)
    return "#{verb} #{path} is not documented and is not on the UNDOCUMENTED allowlist" if others.empty?

    "#{verb} #{path} is not documented — the collection documents #{others.join('/')} for that path"
  end

  describe "resource URLs" do
    model_classes.each do |klass|
      context klass.name.split("::").last do
        it "lists at a documented path" do
          path = klass.url.to_s
          expect(allowed?("GET", path)).to be(true), -> { explain("GET", path) }
        end

        it "reads one at a documented path" do
          path = klass.show_url(":id").to_s
          expect(allowed?("GET", path)).to be(true), -> { explain("GET", path) }
        end
      end
    end
  end

  describe "action endpoints" do
    ACTIONS.each do |action|
      it "#{action[:method]} uses #{action[:verb]} #{action[:path]}" do
        expect(allowed?(action[:verb], action[:path]))
          .to be(true), -> { explain(action[:verb], action[:path]) }
      end
    end
  end

  # Without this, someone adds a new hand-written endpoint, forgets the ACTIONS
  # row, and the contract check silently stops covering it.
  it "has an ACTIONS row for every hand-written request in lib/conexa/resources" do
    found = Dir[File.expand_path("../../lib/conexa/resources/*.rb", __dir__)].flat_map do |path|
      File.readlines(path)
          .grep(/Conexa::Request\.(get|post|put|patch|delete)\b/)
          .map { |line| [File.basename(path), line[/Conexa::Request\.(\w+)/, 1].upcase] }
    end

    expect(found.tally).to eq(ACTIONS.map { |a| [a[:file], a[:verb]] }.tally)
  end
end
