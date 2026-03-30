# frozen_string_literal: true

module Conexa
  # BillSubcategory resource (Subcategoria de Despesa)
  #
  # @example Find a bill subcategory
  #   subcategory = Conexa::BillSubcategory.find(29)
  #   subcategory.name  # => "Taxa de Cartão"
  #
  # @example List bill subcategories
  #   subcategories = Conexa::BillSubcategory.all(limit: 50)
  #
  # @!attribute [r] bill_subcategory_id
  #   @return [Integer] Bill subcategory ID (also accessible as #id)
  # @!attribute [r] name
  #   @return [String] Subcategory name
  # @!attribute [r] bill_category_id
  #   @return [Integer] Parent bill category ID
  # @!attribute [r] is_active
  #   @return [Boolean] Whether the subcategory is active
  #
  class BillSubcategory < Model
    primary_key_attribute :bill_subcategory_id

    class << self
      def url(*params)
        ["/billSubcategories", *params].join '/'
      end

      def show_url(*params)
        ["/billSubcategory", *params].join '/'
      end
    end
  end
end
