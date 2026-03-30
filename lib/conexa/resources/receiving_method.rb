# frozen_string_literal: true

module Conexa
  # ReceivingMethod resource (Meio de Recebimento)
  #
  # @example Find a receiving method
  #   method = Conexa::ReceivingMethod.find(11)
  #   method.name  # => "Cartão de Crédito"
  #
  # @example List receiving methods
  #   methods = Conexa::ReceivingMethod.all(limit: 50)
  #
  # @!attribute [r] receiving_method_id
  #   @return [Integer] Receiving method ID (also accessible as #id)
  # @!attribute [r] name
  #   @return [String] Name
  # @!attribute [r] max_installments
  #   @return [Integer] Maximum number of installments
  # @!attribute [r] credit_days
  #   @return [Integer] Days until credit
  # @!attribute [r] is_installment_fee
  #   @return [Boolean] Whether fee is per installment
  # @!attribute [r] transaction_fee
  #   @return [Float] Fee per transaction
  # @!attribute [r] transaction_rate
  #   @return [Float] Rate percentage per transaction
  # @!attribute [r] account_id
  #   @return [Integer, nil] Associated account ID
  # @!attribute [r] cost_center_id
  #   @return [Integer, nil] Cost center ID
  # @!attribute [r] bill_category_id
  #   @return [Integer, nil] Bill category ID
  # @!attribute [r] bill_subcategory_id
  #   @return [Integer, nil] Bill subcategory ID
  # @!attribute [r] payment_method_id
  #   @return [Integer, nil] Payment method ID
  # @!attribute [r] supplier_id
  #   @return [Integer, nil] Supplier ID
  # @!attribute [r] is_active
  #   @return [Boolean] Whether the receiving method is active
  #
  class ReceivingMethod < Model
    primary_key_attribute :receiving_method_id

    class << self
      def url(*params)
        ["/receivingMethods", *params].join '/'
      end

      def show_url(*params)
        ["/receivingMethod", *params].join '/'
      end
    end
  end
end
