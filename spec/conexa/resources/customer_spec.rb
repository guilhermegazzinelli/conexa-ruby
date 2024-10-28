require 'spec_helper'
require 'conexa'

module Conexa
  RSpec.describe Customer, vcr: { cassette_name: 'customer' } do
    let(:customer_id) { 3 } # ID de exemplo para busca

    describe '.find' do
      it 'retrieves a customer by id' do
        customer = Conexa::Customer.find(customer_id)

        expect(customer).to be_a(Conexa::Customer)
        expect(customer.id).to eq(customer_id)
        expect(customer.name).to_not be_nil
      end
    end

    # describe '.create' do
    #   it 'creates a new customer' do
    #     customer_params = { name: "New Customer", email: "customer@example.com" }

    #     new_customer = Conexa::Customer.create(customer_params)

    #     expect(new_customer).to be_a(Conexa::Customer)
    #     expect(new_customer.name).to eq("New Customer")
    #   end
    # end

    describe '.all' do
      it 'retrieves a list of customers' do
        customers = Conexa::Customer.all

        expect(customers).to be_an(Array)
        expect(customers.first).to be_a(Conexa::Customer)
      end
    end
  end
end