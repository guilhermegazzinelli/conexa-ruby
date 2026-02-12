# frozen_string_literal: true

module Conexa
  # Customer resource for managing clients in Conexa
  #
  # @example Create a customer (Legal Person - PJ)
  #   customer = Conexa::Customer.create(
  #     company_id: 3,
  #     name: 'Empresa ABC Ltda',
  #     legal_person: { cnpj: '99.557.155/0001-90' }
  #   )
  #
  # @example Retrieve a customer
  #   customer = Conexa::Customer.find(127)
  #   customer.name  # => "Empresa ABC Ltda"
  #
  # @example List customers
  #   customers = Conexa::Customer.all(company_id: [3], is_active: true)
  #
  # @!attribute [r] customer_id
  #   @return [Integer] Customer ID (also accessible as #id)
  # @!attribute [r] company_id
  #   @return [Integer] Company/Unit ID
  # @!attribute [r] name
  #   @return [String] Customer name
  # @!attribute [r] trade_name
  #   @return [String, nil] Trade name
  # @!attribute [r] has_login_access
  #   @return [Boolean] Whether customer has login access
  # @!attribute [r] is_active
  #   @return [Boolean] Whether customer is active
  # @!attribute [r] is_blocked
  #   @return [Boolean] Whether customer is blocked
  # @!attribute [r] is_juridical_person
  #   @return [Boolean] Whether customer is a legal person (PJ)
  # @!attribute [r] is_foreign
  #   @return [Boolean] Whether customer is a foreigner
  # @!attribute [r] legal_person
  #   @return [Hash, nil] Legal person data (cnpj, foundation_date, etc.)
  # @!attribute [r] natural_person
  #   @return [Hash, nil] Natural person data (cpf, birth_date, etc.)
  # @!attribute [r] created_at
  #   @return [String, nil] Created at timestamp (W3C format)
  #
  class Customer < Model
    primary_key_attribute :customer_id

    # @return [Array<String>] Phone numbers (empty array if null)
    def phones
      @attributes['phones'] || []
    end

    # @return [Array<String>] Message emails (empty array if null)
    def emails_message
      @attributes['emails_message'] || []
    end

    # @return [Array<String>] Financial emails (empty array if null)
    def emails_financial_messages
      @attributes['emails_financial_messages'] || []
    end

    # @return [Array<Integer>] Tag IDs (empty array if null)
    def tags_id
      @attributes['tags_id'] || []
    end

    # @return [Address, nil] Customer address
    def address
      return nil unless @attributes['address']
      Address.new(@attributes['address'])
    end

    class << self
      # List persons (requesters) for a customer
      # @param customer_id [Integer] Customer ID
      # @return [Result] List of persons
      def persons(customer_id)
        Conexa::Person.all(customer_id: customer_id)
      end

      # List contracts for a customer
      # @param customer_id [Integer] Customer ID
      # @return [Result] List of contracts
      def contracts(customer_id)
        Conexa::Contract.all(customer_id: [customer_id])
      end

      # List charges for a customer
      # @param customer_id [Integer] Customer ID
      # @return [Result] List of charges
      def charges(customer_id)
        Conexa::Charge.all(customer_id: [customer_id])
      end
    end
  end
end
