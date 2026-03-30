# frozen_string_literal: true

module Conexa
  # PaymentMethod resource (Meio de Pagamento)
  #
  # @example Find a payment method
  #   method = Conexa::PaymentMethod.find(2)
  #   method.name  # => "Boleto"
  #
  # @example List payment methods
  #   methods = Conexa::PaymentMethod.all(limit: 50)
  #
  # @!attribute [r] payment_method_id
  #   @return [Integer] Payment method ID (also accessible as #id)
  # @!attribute [r] name
  #   @return [String] Name
  # @!attribute [r] is_active
  #   @return [Boolean] Whether the payment method is active
  #
  class PaymentMethod < Model
    primary_key_attribute :payment_method_id

    class << self
      def url(*params)
        ["/paymentMethods", *params].join '/'
      end

      def show_url(*params)
        ["/paymentMethod", *params].join '/'
      end
    end
  end
end
