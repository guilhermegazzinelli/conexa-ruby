# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Customer Integration", :vcr do
  describe "CRUD operations" do
    describe "listing customers", vcr: { cassette_name: "customer" } do
      it "returns a list of customers with pagination" do
        result = Conexa::Customer.all(page: 1, size: 100)

        expect(result).to respond_to(:data)
        expect(result).to respond_to(:pagination)
        expect(result.data).to be_an(Array)
        expect(result.pagination.current_page).to eq(1)
      end

      it "returns customer objects with attributes" do
        result = Conexa::Customer.all(page: 1, size: 100)
        customer = result.data.first

        expect(customer).to respond_to(:name)
        expect(customer).to respond_to(:customer_id)
        expect(customer.name).to be_a(String)
      end
    end

    describe "finding a customer", vcr: { cassette_name: "customer" } do
      it "returns a single customer by id" do
        customer = Conexa::Customer.find(3)

        expect(customer).to respond_to(:customer_id)
        expect(customer.customer_id).to eq(3)
        expect(customer.name).to eq("ROTULA METALURGICA LTDA")
      end

      it "includes nested address data" do
        customer = Conexa::Customer.find(3)

        expect(customer.address).to respond_to(:city)
        expect(customer.address.city).to eq("Salvador")
      end

      it "includes nested legal_person data for juridical persons" do
        customer = Conexa::Customer.find(3)

        expect(customer.is_juridical_person).to eq(true)
        expect(customer.legal_person).to respond_to(:cnpj)
        expect(customer.legal_person.cnpj).to include("33.871.336")
      end
    end
  end

  describe "data transformation" do
    describe "with VCR cassette", vcr: { cassette_name: "customer" } do
      it "converts camelCase response to snake_case attributes" do
        customer = Conexa::Customer.find(3)

        # These should be accessible as snake_case
        expect(customer).to respond_to(:customer_id)
        expect(customer).to respond_to(:company_id)
        expect(customer).to respond_to(:is_active)
        expect(customer).to respond_to(:cell_number)
      end

      it "provides access to nested objects" do
        customer = Conexa::Customer.find(3)

        expect(customer.address.state).to respond_to(:abbreviation)
        expect(customer.address.state.abbreviation).to eq("BA")
      end
    end
  end
end
