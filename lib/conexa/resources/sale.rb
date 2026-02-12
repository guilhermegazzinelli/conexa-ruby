# frozen_string_literal: true

module Conexa
  # Sale resource for one-time sales
  #
  # @example Create a sale
  #   sale = Conexa::Sale.create(
  #     customerId: 450,
  #     productId: 2521,
  #     quantity: 1,
  #     amount: 80.99
  #   )
  #
  # @example List sales
  #   sales = Conexa::Sale.all(customerId: [450], status: 'notBilled')
  #
  class Sale < Model
    # @return [Integer] Sale ID
    def saleId
      @attributes['saleId']
    end

    alias_method :id, :saleId

    # @return [String] Sale status: paid, billed, cancelled, notBilled, 
    #   deductedFromQuota, billedCancelled, billedNegociated, partiallyPaid
    def status
      @attributes['status']
    end

    # @return [Integer] Customer ID
    def customerId
      @attributes['customerId']
    end

    # @return [Integer, nil] Requester ID
    def requesterId
      @attributes['requesterId']
    end

    # @return [Integer] Product ID
    def productId
      @attributes['productId']
    end

    # @return [Integer, nil] Seller (user) ID
    def sellerId
      @attributes['sellerId']
    end

    # @return [Integer] Quantity
    def quantity
      @attributes['quantity']
    end

    # @return [Float] Final amount
    def amount
      @attributes['amount']
    end

    # @return [Float] Original amount before discount
    def originalAmount
      @attributes['originalAmount']
    end

    # @return [Float] Discount value
    def discountValue
      @attributes['discountValue']
    end

    # @return [String] Reference date (W3C format)
    def referenceDate
      @attributes['referenceDate']
    end

    # @return [String, nil] Notes
    def notes
      @attributes['notes']
    end

    # @return [String, nil] Created at timestamp
    def createdAt
      @attributes['createdAt']
    end

    # @return [String] Updated at timestamp
    def updatedAt
      @attributes['updatedAt']
    end

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
