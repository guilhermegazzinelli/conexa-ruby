module Conexa
  # Product resource (read-only for listing/retrieving)
  #
  # The new API v2 also supports POST /product and DELETE /product/:id.
  #
  # @example Find a product
  #   product = Conexa::Product.find(100)
  #   product.name  # => "Mensalidade"
  #
  # @example List products
  #   products = Conexa::Product.all(company_id: [3], limit: 50)
  #
  # @example Create a product
  #   product = Conexa::Product.create(name: 'Novo Produto', company_id: 3)
  #
  # @example Delete a product
  #   Conexa::Product.destroy(100)
  #
  # @!attribute [r] product_id
  #   @return [Integer] Product ID (also accessible as #id)
  # @!attribute [r] name
  #   @return [String] Product name
  # @!attribute [r] is_active
  #   @return [Boolean] Whether the product is active
  #
  class Product < Model
    primary_key_attribute :product_id
  end
end
