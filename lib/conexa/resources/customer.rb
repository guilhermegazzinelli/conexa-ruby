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
    # @return [Integer] Customer ID
    def customer_id
      @attributes['customer_id']
    end
    alias_method :customerId, :customer_id
    alias_method :id, :customer_id

    # @return [Integer] Company/Unit ID
    def company_id
      @attributes['company_id']
    end
    alias_method :companyId, :company_id

    # @return [String] Customer name
    def name
      @attributes['name']
    end

    # @return [String, nil] Trade name
    def trade_name
      @attributes['trade_name']
    end
    alias_method :tradeName, :trade_name

    # @return [Boolean] Whether customer has login access
    def has_login_access
      @attributes['has_login_access']
    end
    alias_method :hasLoginAccess, :has_login_access

    # @return [Boolean] Whether customer is active
    def is_active
      @attributes['is_active']
    end
    alias_method :isActive, :is_active

    # @return [Boolean] Whether customer is blocked
    def is_blocked
      @attributes['is_blocked']
    end
    alias_method :isBlocked, :is_blocked

    # @return [Boolean] Whether customer is a legal person (PJ)
    def is_juridical_person
      @attributes['is_juridical_person']
    end
    alias_method :isJuridicalPerson, :is_juridical_person

    # @return [Boolean] Whether customer is a foreigner
    def is_foreign
      @attributes['is_foreign']
    end
    alias_method :isForeign, :is_foreign

    # @return [Address, nil] Customer address
    def address
      return nil unless @attributes['address']
      Address.new(@attributes['address'])
    end

    # @return [Hash, nil] Legal person data (CNPJ, etc.)
    def legal_person
      @attributes['legal_person']
    end
    alias_method :legalPerson, :legal_person

    # @return [Hash, nil] Natural person data (CPF, etc.)
    def natural_person
      @attributes['natural_person']
    end
    alias_method :naturalPerson, :natural_person

    # @return [Array<String>] Phone numbers
    def phones
      @attributes['phones'] || []
    end

    # @return [Array<String>] Message emails
    def emails_message
      @attributes['emails_message'] || []
    end
    alias_method :emailsMessage, :emails_message

    # @return [Array<String>] Financial emails
    def emails_financial_messages
      @attributes['emails_financial_messages'] || []
    end
    alias_method :emailsFinancialMessages, :emails_financial_messages

    # @return [Array<Integer>] Tag IDs
    def tags_id
      @attributes['tags_id'] || []
    end
    alias_method :tagsId, :tags_id

    # @return [String, nil] Created at timestamp (W3C format)
    def created_at
      @attributes['created_at']
    end
    alias_method :createdAt, :created_at

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
