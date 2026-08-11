# frozen_string_literal: true

require "spec_helper"

# Util.camelize_hash recursed into nested Hashes but treated an Array as a scalar,
# so snake_case keys inside arrays of objects went out untouched and the API
# rejected the payload:
#
#   {"complementaryServices":[{"product_or_service_id":2113}]}
#     => 400 "complementaryServices.productOrServiceId ... does not exist"
#
# Ten documented endpoints across seven resources take arrays of objects, so this
# silently blocked a large part of the write surface.
RSpec.describe "nested payload camelization" do
  describe Conexa::Util do
    it "camelizes keys inside an array of objects" do
      result = described_class.camelize_hash(
        complementary_services: [{ product_or_service_id: 2113, quantity: 3 }]
      )

      expect(result).to eq(complementaryServices: [{ productOrServiceId: 2113, quantity: 3 }])
    end

    it "camelizes arbitrarily deep mixes of hashes and arrays" do
      result = described_class.camelize_hash(
        expense_settlement: { receiving_method_id: 53, account_id: 1 },
        product_quotas: [{ product_id: 9, quantity: 1 }],
        extra_fields: [{ id: 1, value: "x" }, { id: 2, value: "y" }],
        booking_models: [{ id: 3, stations: [{ station_id: 4 }] }]
      )

      expect(result).to eq(
        expenseSettlement: { receivingMethodId: 53, accountId: 1 },
        productQuotas: [{ productId: 9, quantity: 1 }],
        extraFields: [{ id: 1, value: "x" }, { id: 2, value: "y" }],
        bookingModels: [{ id: 3, stations: [{ stationId: 4 }] }]
      )
    end

    it "leaves arrays of scalars alone" do
      expect(described_class.camelize_hash(customer_id: [1, 2, 3]))
        .to eq(customerId: [1, 2, 3])
    end

    it "still returns {} for nil" do
      expect(described_class.camelize_hash(nil)).to eq({})
    end
  end

  # The documented array-of-object bodies, per docs/postman-collection.json.
  # Model#create POSTs and then re-fetches, so the request under test is the
  # first one; the fixed body gives the fetch an id to work with.
  describe "on the wire" do
    def creation_payload(&block)
      sent_payload(capture_requests(body: '{"data":{"id":1}}', &block).first)
    end

    it "sends complementaryServices with camelCase keys on contract create" do
      payload = creation_payload do
        Conexa::Contract.create(
          plan_id: 12,
          customer_id: 42,
          complementary_services: [{ product_or_service_id: 2113, quantity: 3, amount: 200 }]
        )
      end

      expect(payload["complementaryServices"])
        .to eq([{ "productOrServiceId" => 2113, "quantity" => 3, "amount" => 200 }])
    end

    it "sends devices with camelCase keys on person create" do
      payload = creation_payload do
        Conexa::Person.create(name: "X", devices: [{ nickname: "n", mac_address: "AA:BB" }])
      end

      expect(payload["devices"]).to eq([{ "nickname" => "n", "macAddress" => "AA:BB" }])
    end

    it "sends the atomic create-and-settle payload intact" do
      payload = creation_payload do
        Conexa::Contract.create(
          plan_id: 12,
          customer_id: 42,
          generate_sales: "firstOccurrenceSettleRetroactive",
          expense_settlement: { receiving_method_id: 53, account_id: 1 }
        )
      end

      expect(payload).to include(
        "generateSales"     => "firstOccurrenceSettleRetroactive",
        "expenseSettlement" => { "receivingMethodId" => 53, "accountId" => 1 }
      )
    end
  end
end
