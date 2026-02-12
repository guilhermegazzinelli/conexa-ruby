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
  class Customer < Model
    primary_key_attribute :customer_id
    attribute :company_id
    attribute :name
    attribute :trade_name
    attribute :has_login_access
    attribute :is_active
    attribute :is_blocked
    attribute :is_juridical_person
    attribute :is_foreign
    attribute :legal_person
    attribute :natural_person
    attribute :phones
    attribute :emails_message
    attribute :emails_financial_messages
    attribute :tags_id
    attribute :created_at

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
