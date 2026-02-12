# frozen_string_literal: true

module Conexa
  # Customer resource for managing clients in Conexa
  #
  # @example Create a customer (Legal Person - PJ)
  #   customer = Conexa::Customer.create(
  #     companyId: 3,
  #     name: 'Empresa ABC Ltda',
  #     legalPerson: { cnpj: '99.557.155/0001-90' }
  #   )
  #
  # @example Retrieve a customer
  #   customer = Conexa::Customer.find(127)
  #   customer.name  # => "Empresa ABC Ltda"
  #
  # @example List customers
  #   customers = Conexa::Customer.all(companyId: [3], isActive: true)
  #
  class Customer < Model
    # @return [Integer] Customer ID
    def customerId
      @attributes['customerId']
    end

    alias_method :id, :customerId

    # @return [Integer] Company/Unit ID
    def companyId
      @attributes['companyId']
    end

    # @return [String] Customer name
    def name
      @attributes['name']
    end

    # @return [String, nil] Trade name
    def tradeName
      @attributes['tradeName']
    end

    # @return [Boolean] Whether customer has login access
    def hasLoginAccess
      @attributes['hasLoginAccess']
    end

    # @return [Boolean] Whether customer is active
    def isActive
      @attributes['isActive']
    end

    # @return [Boolean] Whether customer is blocked
    def isBlocked
      @attributes['isBlocked']
    end

    # @return [Boolean] Whether customer is a legal person (PJ)
    def isJuridicalPerson
      @attributes['isJuridicalPerson']
    end

    # @return [Boolean] Whether customer is a foreigner
    def isForeign
      @attributes['isForeign']
    end

    # @return [Address, nil] Customer address
    def address
      return nil unless @attributes['address']
      Address.new(@attributes['address'])
    end

    # @return [Hash, nil] Legal person data (CNPJ, etc.)
    def legalPerson
      @attributes['legalPerson']
    end

    # @return [Hash, nil] Natural person data (CPF, etc.)
    def naturalPerson
      @attributes['naturalPerson']
    end

    # @return [Array<String>] Phone numbers
    def phones
      @attributes['phones'] || []
    end

    # @return [Array<String>] Message emails
    def emailsMessage
      @attributes['emailsMessage'] || []
    end

    # @return [Array<String>] Financial emails
    def emailsFinancialMessages
      @attributes['emailsFinancialMessages'] || []
    end

    # @return [Array<Integer>] Tag IDs
    def tagsId
      @attributes['tagsId'] || []
    end

    # @return [String, nil] Created at timestamp (W3C format)
    def createdAt
      @attributes['createdAt']
    end

    class << self
      # List persons (requesters) for a customer
      # @param customer_id [Integer] Customer ID
      # @return [Result] List of persons
      def persons(customer_id)
        Conexa::Person.all(customerId: customer_id)
      end

      # List contracts for a customer
      # @param customer_id [Integer] Customer ID
      # @return [Result] List of contracts
      def contracts(customer_id)
        Conexa::Contract.all(customerId: [customer_id])
      end

      # List charges for a customer
      # @param customer_id [Integer] Customer ID
      # @return [Result] List of charges
      def charges(customer_id)
        Conexa::Charge.all(customerId: [customer_id])
      end
    end
  end
end
