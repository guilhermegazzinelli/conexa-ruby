module Conexa
  class Charge < Model
    # Settle (pay) a charge
    # @param params [Hash] optional parameters (e.g., payment details)
    # @return [self]
    def settle(params = {})
      Conexa::Request.post(self.class.show_url("settle", primary_key), params: params).call(class_name)
      self
    end

    # Get PIX QR Code for the charge
    # @return [ConexaObject] PIX data including QR code
    def pix
      Conexa::Request.get(self.class.show_url("pix", primary_key)).call("pix")
    end

    class << self
      # Settle a charge by ID
      # @param id [Integer, String] charge ID
      # @param params [Hash] optional parameters
      # @return [Charge]
      def settle(id, params = {})
        find(id).settle(params)
      end

      # Get PIX QR Code for a charge by ID
      # @param id [Integer, String] charge ID
      # @return [ConexaObject] PIX data including QR code
      def pix(id)
        find(id).pix
      end
    end
  end
end
