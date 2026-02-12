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
  class Contract < Model
    # @return [Integer] Contract ID
    def contract_id
      @attributes['contract_id']
    end
    alias_method :contractId, :contract_id
    alias_method :id, :contract_id

    # @return [String] Contract status
    def status
      @attributes['status']
    end

    # @return [Integer] Customer ID
    def customer_id
      @attributes['customer_id']
    end
    alias_method :customerId, :customer_id

    # @return [Integer, nil] Plan ID
    def plan_id
      @attributes['plan_id']
    end
    alias_method :planId, :plan_id

    # @return [String] Start date
    def start_date
      @attributes['start_date']
    end
    alias_method :startDate, :start_date

    # @return [String, nil] End date
    def end_date
      @attributes['end_date']
    end
    alias_method :endDate, :end_date

    # @return [Integer] Payment day (1-28)
    def payment_day
      @attributes['payment_day']
    end
    alias_method :paymentDay, :payment_day

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
