# frozen_string_literal: true

module Conexa
  # CostCenter resource (Centro de Custo)
  #
  # @example Find a cost center
  #   center = Conexa::CostCenter.find(11)
  #   center.name  # => "Marketing"
  #
  # @example List cost centers
  #   centers = Conexa::CostCenter.all(limit: 50)
  #
  # @!attribute [r] cost_center_id
  #   @return [Integer] Cost center ID (also accessible as #id)
  # @!attribute [r] name
  #   @return [String] Cost center name
  # @!attribute [r] is_active
  #   @return [Boolean] Whether the cost center is active
  #
  class CostCenter < Model
    primary_key_attribute :cost_center_id

    class << self
      def url(*params)
        ["/costCenters", *params].join '/'
      end

      def show_url(*params)
        ["/costCenter", *params].join '/'
      end
    end
  end
end
