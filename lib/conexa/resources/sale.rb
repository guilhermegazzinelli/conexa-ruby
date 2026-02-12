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
  class Sale < Model
    primary_key_attribute :sale_id
    attribute :customer_id
    attribute :requester_id
    attribute :product_id
    attribute :seller_id
    attribute :quantity
    attribute :amount
    attribute :original_amount
    attribute :discount_value
    attribute :reference_date
    attribute :notes
    attribute :created_at
    attribute :updated_at
    attribute :status

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
