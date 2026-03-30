# frozen_string_literal: true

module Conexa
  # Supplier resource (Fornecedor)
  #
  # @example Create a supplier
  #   supplier = Conexa::Supplier.create(name: 'Fornecedor ABC')
  #
  # @example Find a supplier
  #   supplier = Conexa::Supplier.find(10)
  #   supplier.name  # => "Fornecedor ABC"
  #
  # @example List suppliers
  #   suppliers = Conexa::Supplier.all(limit: 50)
  #
  # @!attribute [r] supplier_id
  #   @return [Integer] Supplier ID (also accessible as #id)
  # @!attribute [r] name
  #   @return [String] Supplier name
  # @!attribute [r] is_active
  #   @return [Boolean] Whether the supplier is active
  #
  class Supplier < Model
    primary_key_attribute :supplier_id

    class << self
      def url(*params)
        ["/suppliers", *params].join '/'
      end

      def show_url(*params)
        ["/supplier", *params].join '/'
      end
    end
  end
end
