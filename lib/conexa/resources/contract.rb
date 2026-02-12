# frozen_string_literal: true

module Conexa
  # Contract resource for recurring billing contracts
  #
  # @example Create a contract
  #   contract = Conexa::Contract.create(
  #     customerId: 127,
  #     planId: 5,
  #     startDate: '2024-01-01',
  #     paymentDay: 10
  #   )
  #
  # @example End a contract
  #   Conexa::Contract.end_contract(456, endDate: '2024-12-31')
  #
  class Contract < Model
    # @return [Integer] Contract ID
    def contractId
      @attributes['contractId']
    end

    alias_method :id, :contractId

    # @return [String] Contract status
    def status
      @attributes['status']
    end

    # @return [Integer] Customer ID
    def customerId
      @attributes['customerId']
    end

    # @return [Integer, nil] Plan ID
    def planId
      @attributes['planId']
    end

    # @return [String] Start date
    def startDate
      @attributes['startDate']
    end

    # @return [String, nil] End date
    def endDate
      @attributes['endDate']
    end

    # @return [Integer] Payment day (1-28)
    def paymentDay
      @attributes['paymentDay']
    end

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
    # @param params [Hash] options including :endDate, :reason
    # @return [self]
    def end_contract(params = {})
      Conexa::Request.post(self.class.show_url("end", primary_key), params: params).call(class_name)
      self
    end

    class << self
      # End a contract by ID
      # @param id [Integer, String] contract ID
      # @param params [Hash] options including :endDate, :reason
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
