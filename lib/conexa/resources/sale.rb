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
    # @return [Integer] Sale ID
    def sale_id
      @attributes['sale_id']
    end
    alias_method :saleId, :sale_id
    alias_method :id, :sale_id

    # @return [String] Sale status: paid, billed, cancelled, notBilled, 
    #   deductedFromQuota, billedCancelled, billedNegociated, partiallyPaid
    def status
      @attributes['status']
    end

    # @return [Integer] Customer ID
    def customer_id
      @attributes['customer_id']
    end
    alias_method :customerId, :customer_id

    # @return [Integer, nil] Requester ID
    def requester_id
      @attributes['requester_id']
    end
    alias_method :requesterId, :requester_id

    # @return [Integer] Product ID
    def product_id
      @attributes['product_id']
    end
    alias_method :productId, :product_id

    # @return [Integer, nil] Seller (user) ID
    def seller_id
      @attributes['seller_id']
    end
    alias_method :sellerId, :seller_id

    # @return [Integer] Quantity
    def quantity
      @attributes['quantity']
    end

    # @return [Float] Final amount
    def amount
      @attributes['amount']
    end

    # @return [Float] Original amount before discount
    def original_amount
      @attributes['original_amount']
    end
    alias_method :originalAmount, :original_amount

    # @return [Float] Discount value
    def discount_value
      @attributes['discount_value']
    end
    alias_method :discountValue, :discount_value

    # @return [String] Reference date (W3C format)
    def reference_date
      @attributes['reference_date']
    end
    alias_method :referenceDate, :reference_date

    # @return [String, nil] Notes
    def notes
      @attributes['notes']
    end

    # @return [String, nil] Created at timestamp
    def created_at
      @attributes['created_at']
    end
    alias_method :createdAt, :created_at

    # @return [String] Updated at timestamp
    def updated_at
      @attributes['updated_at']
    end
    alias_method :updatedAt, :updated_at

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
