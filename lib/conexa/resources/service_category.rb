# frozen_string_literal: true

module Conexa
  # ServiceCategory resource (Categoria de Serviço)
  #
  # @example Find a service category
  #   category = Conexa::ServiceCategory.find(1)
  #   category.name  # => "Consultoria"
  #
  # @example List service categories
  #   categories = Conexa::ServiceCategory.all(limit: 50)
  #
  # @!attribute [r] service_category_id
  #   @return [Integer] Service category ID (also accessible as #id)
  # @!attribute [r] name
  #   @return [String] Category name
  # @!attribute [r] is_active
  #   @return [Boolean] Whether the category is active
  #
  class ServiceCategory < Model
    primary_key_attribute :service_category_id

    class << self
      def url(*params)
        ["/serviceCategories", *params].join '/'
      end

      def show_url(*params)
        ["/serviceCategory", *params].join '/'
      end
    end
  end
end
