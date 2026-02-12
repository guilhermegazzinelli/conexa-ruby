# frozen_string_literal: true

module Conexa
  # Sale resource for one-time sales
  #
  # @example Create a sale
  #   sale = Conexa::Sale.create(
  #     customer_id: 450,
  #     product_id: 2521,
  #     quantity: 1,
  #     amount: 80.99
  #   )
  #
  # @example List sales
  #   sales = Conexa::Sale.all(customer_id: [450], status: 'notBilled')
  #
  # @!attribute [r] sale_id
  #   @return [Integer] Sale ID (also accessible as #id)
  # @!attribute [r] customer_id
  #   @return [Integer] Customer ID
  # @!attribute [r] requester_id
  #   @return [Integer, nil] Requester ID
  # @!attribute [r] product_id
  #   @return [Integer] Product ID
  # @!attribute [r] seller_id
  #   @return [Integer, nil] Seller (user) ID
  # @!attribute [r] status
  #   @return [String] Status: paid, billed, cancelled, notBilled, 
  #     deductedFromQuota, billedCancelled, billedNegociated, partiallyPaid
  # @!attribute [r] quantity
  #   @return [Integer] Quantity
  # @!attribute [r] amount
  #   @return [Float] Final amount
  # @!attribute [r] original_amount
  #   @return [Float] Original amount before discount
  # @!attribute [r] discount_value
  #   @return [Float] Discount value
  # @!attribute [r] reference_date
  #   @return [String] Reference date (W3C format)
  # @!attribute [r] notes
  #   @return [String, nil] Notes
  # @!attribute [r] created_at
  #   @return [String, nil] Created at timestamp
  # @!attribute [r] updated_at
  #   @return [String] Updated at timestamp
  #
  class Sale < Model
    primary_key_attribute :sale_id

    # Check if sale is billed
    # @return [Boolean]
    def billed?
      status == 'billed'
    end

    # Check if sale is paid
    # @return [Boolean]
    def paid?
      status == 'paid'
    end

    # Check if sale can be edited
    # @return [Boolean]
    def editable?
      status == 'notBilled'
    end

    class << self
      def url(*params)
        ["/sales", *params].join '/'
      end

      def show_url(*params)
        ["/sale", *params].join '/'
      end
    end
  end
end
