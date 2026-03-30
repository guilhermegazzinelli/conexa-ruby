# frozen_string_literal: true

module Conexa
  # BillCategory resource (Categoria de Despesa)
  #
  # @example Find a bill category
  #   category = Conexa::BillCategory.find(4)
  #   category.name  # => "Impostos"
  #
  # @example List bill categories
  #   categories = Conexa::BillCategory.all(limit: 50)
  #
  # @!attribute [r] bill_category_id
  #   @return [Integer] Bill category ID (also accessible as #id)
  # @!attribute [r] name
  #   @return [String] Category name
  # @!attribute [r] is_active
  #   @return [Boolean] Whether the category is active
  #
  class BillCategory < Model
    primary_key_attribute :bill_category_id

    class << self
      def url(*params)
        ["/billCategories", *params].join '/'
      end

      def show_url(*params)
        ["/billCategory", *params].join '/'
      end
    end
  end
end
