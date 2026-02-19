# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Plan Integration" do
  around(:each) do |example|
    VCR.turned_off do
      WebMock.enable!
      example.run
    end
  end

  before do
    Conexa.configure do |c|
      c.api_token = "test_token"
      c.api_host = "https://test.conexa.app"
    end
  end

  let(:plan_response) do
    {
      "planId" => 5,
      "companyId" => 1,
      "name" => "Plano Basico",
      "serviceCategoryId" => 1,
      "description" => "Plano com recursos basicos",
      "membershipFee" => 200.00,
      "refundValue" => 1500.00,
      "fidelityMonths" => 12,
      "paymentPeriodicities" => [
        { "periodicity" => "monthly", "amount" => 500.00 },
        { "periodicity" => "yearly", "amount" => 5000.00 }
      ],
      "productQuotas" => [
        { "productId" => 100, "quantity" => 10 }
      ]
    }.to_json
  end

  let(:plans_list_response) do
    {
      "data" => [
        { "planId" => 5, "name" => "Plano Basico", "companyId" => 1 },
        { "planId" => 6, "name" => "Plano Premium", "companyId" => 1 }
      ],
      "pagination" => { "currentPage" => 1, "totalPages" => 1, "totalItems" => 2, "itemPerPage" => 100 }
    }.to_json
  end

  describe "listing plans" do
    before do
      stub_request(:get, /test\.conexa\.app.*plans/)
        .to_return(status: 200, body: plans_list_response, headers: { "Content-Type" => "application/json" })
    end

    it "returns a list of plans" do
      result = Conexa::Plan.all
      expect(result.data).to be_an(Array)
      expect(result.data.length).to eq(2)
    end

    it "returns plan objects with attributes" do
      result = Conexa::Plan.all
      plan = result.data.first
      expect(plan.name).to eq("Plano Basico")
      expect(plan.company_id).to eq(1)
    end
  end

  describe "finding a plan" do
    before do
      stub_request(:get, /test\.conexa\.app.*plan\/5/)
        .to_return(status: 200, body: plan_response, headers: { "Content-Type" => "application/json" })
    end

    it "returns a plan by id" do
      plan = Conexa::Plan.find(5)
      expect(plan).to be_a(Conexa::Plan)
      expect(plan.name).to eq("Plano Basico")
      expect(plan.description).to eq("Plano com recursos basicos")
    end

    it "includes nested data" do
      plan = Conexa::Plan.find(5)
      expect(plan.payment_periodicities).to be_an(Array)
      expect(plan.payment_periodicities.length).to eq(2)
      expect(plan.product_quotas).to be_an(Array)
      expect(plan.membership_fee).to eq(200.00)
      expect(plan.fidelity_months).to eq(12)
    end
  end

  describe "creating a plan" do
    before do
      stub_request(:post, /test\.conexa\.app.*plan/)
        .to_return(status: 200, body: { "id" => 5 }.to_json, headers: { "Content-Type" => "application/json" })

      stub_request(:get, /test\.conexa\.app.*plan\/5/)
        .to_return(status: 200, body: plan_response, headers: { "Content-Type" => "application/json" })
    end

    it "creates a plan" do
      plan = Conexa::Plan.create(
        company_id: 1,
        name: "Plano Basico",
        service_category_id: 1,
        payment_periodicities: [
          { periodicity: "monthly", amount: 500.00 }
        ]
      )
      expect(plan).to be_a(Conexa::Plan)
      expect(plan.name).to eq("Plano Basico")
    end
  end

  describe "save raises NoMethodError" do
    it "cannot update a plan via save" do
      plan = Conexa::Plan.new("planId" => 5, "name" => "Test")
      expect { plan.save }.to raise_error(NoMethodError)
    end
  end

  describe "deleting a plan" do
    before do
      stub_request(:delete, /test\.conexa\.app.*plan\/5/)
        .to_return(status: 200, body: plan_response, headers: { "Content-Type" => "application/json" })
    end

    it "deletes a plan" do
      result = Conexa::Plan.destroy(5)
      expect(result).to be_a(Conexa::Plan)
    end
  end
end
