# frozen_string_literal: true

require "spec_helper"

RSpec.describe Conexa::Address do
  describe "inheritance" do
    it "inherits from ConexaObject" do
      expect(described_class.superclass).to eq(Conexa::ConexaObject)
    end
  end

  describe "instance" do
    it "can be instantiated with attributes" do
      address = described_class.new(
        "street" => "Rua Principal",
        "number" => "123",
        "city" => "São Paulo",
        "state" => "SP",
        "zip_code" => "01234-567"
      )

      expect(address.street).to eq("Rua Principal")
      expect(address.number).to eq("123")
      expect(address.city).to eq("São Paulo")
    end
  end
end
