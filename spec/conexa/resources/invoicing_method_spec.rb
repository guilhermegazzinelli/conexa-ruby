# frozen_string_literal: true

require "spec_helper"

RSpec.describe Conexa::InvoicingMethod do
  describe "inheritance" do
    it "inherits from Model" do
      expect(described_class.superclass).to eq(Conexa::Model)
    end
  end

  describe "class methods" do
    describe ".url" do
      it "returns invoicingMethods endpoint" do
        expect(described_class.url).to eq("/invoicingMethods")
      end

      it "joins additional params with /" do
        expect(described_class.url("active")).to eq("/invoicingMethods/active")
        expect(described_class.url("123", "details")).to eq("/invoicingMethods/123/details")
      end
    end

    describe ".show_url" do
      it "returns invoicingMethod endpoint (singular)" do
        expect(described_class.show_url).to eq("/invoicingMethod")
      end

      it "returns invoicingMethod endpoint with id" do
        expect(described_class.show_url("123")).to eq("/invoicingMethod/123")
      end

      it "joins multiple params" do
        expect(described_class.show_url("123", "items")).to eq("/invoicingMethod/123/items")
      end
    end
  end
end
