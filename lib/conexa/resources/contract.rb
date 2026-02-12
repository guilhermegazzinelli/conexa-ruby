# frozen_string_literal: true

module Conexa
  # Contract resource for recurring billing contracts
  #
  # @example Create a contract
  #   contract = Conexa::Contract.create(
  #     customer_id: 127,
  #     plan_id: 5,
  #     start_date: '2024-01-01',
  #     payment_day: 10
  #   )
  #
  # @example End a contract
  #   Conexa::Contract.end_contract(456, end_date: '2024-12-31')
  #
  # @!attribute [r] contract_id
  #   @return [Integer] Contract ID (also accessible as #id)
  # @!attribute [r] customer_id
  #   @return [Integer] Customer ID
  # @!attribute [r] plan_id
  #   @return [Integer, nil] Plan ID
  # @!attribute [r] status
  #   @return [String] Status: active, ended, cancelled
  # @!attribute [r] start_date
  #   @return [String] Start date
  # @!attribute [r] end_date
  #   @return [String, nil] End date
  # @!attribute [r] payment_day
  #   @return [Integer] Payment day (1-28)
  # @!attribute [r] value
  #   @return [Float] Contract value
  # @!attribute [r] billing_day
  #   @return [Integer] Billing day
  #
  class Contract < Model
    primary_key_attribute :contract_id

    # Check if contract is active
    # @return [Boolean]
    def active?
      status == 'active'
    end

    # Check if contract is cancelled/ended
    # @return [Boolean]
    def ended?
      status == 'ended' || status == 'cancelled'
    end

    # End/terminate this contract
    # @param params [Hash] options including :end_date, :reason
    # @return [self]
    def end_contract(params = {})
      Conexa::Request.post(self.class.show_url("end", primary_key), params: params).call(class_name)
      self
    end

    class << self
      # End a contract by ID
      # @param id [Integer, String] contract ID
      # @param params [Hash] options including :end_date, :reason
      # @return [Contract]
      def end_contract(id, params = {})
        find(id).end_contract(params)
      end

      # Create contract with custom product items
      # @param params [Hash] contract params including :items array
      # @return [Contract]
      def create_with_products(params = {})
        create(params)
      end
    end
  end
end
