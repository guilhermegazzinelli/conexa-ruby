# frozen_string_literal: true

require "spec_helper"

RSpec.describe Conexa::LegalPerson do
  describe "inheritance" do
    it "inherits from ConexaObject" do
      expect(described_class.superclass).to eq(Conexa::ConexaObject)
    end
  end

  describe "instance" do
    it "can be instantiated with attributes" do
      legal_person = described_class.new(
        "company_name" => "ACME Corp",
        "trading_name" => "ACME",
        "cnpj" => "12.345.678/0001-90",
        "state_registration" => "123456789"
      )

      expect(legal_person.company_name).to eq("ACME Corp")
      expect(legal_person.trading_name).to eq("ACME")
      expect(legal_person.cnpj).to eq("12.345.678/0001-90")
    end
  end
end
