# frozen_string_literal: true

require "spec_helper"

RSpec.describe Conexa::Addres do
  describe "inheritance" do
    it "inherits from ConexaObject" do
      expect(described_class.superclass).to eq(Conexa::ConexaObject)
    end
  end

  describe "instance" do
    it "can be instantiated with attributes" do
      addres = described_class.new(
        "street" => "Rua Principal",
        "number" => "123",
        "city" => "São Paulo",
        "state" => "SP",
        "zip_code" => "01234-567"
      )

      expect(addres.street).to eq("Rua Principal")
      expect(addres.number).to eq("123")
      expect(addres.city).to eq("São Paulo")
    end
  end
end
