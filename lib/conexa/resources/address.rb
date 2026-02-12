# frozen_string_literal: true

module Conexa
  # Represents an address object (embedded in Customer, etc.)
  # Not a standalone API resource - used for serialization/deserialization
  class Address < ConexaObject
    # @return [String, nil] CEP/ZIP code
    # @return [String, nil] Street name
    # @return [String, nil] Street number
    # @return [String, nil] Neighborhood
    # @return [String, nil] City
    # @return [String, nil] State abbreviation (UF)
    # @return [String, nil] Country (for foreigners)
    # @return [String, nil] Additional details (complement)
  end
end
