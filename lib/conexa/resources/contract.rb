module Conexa
  class Contract < Model
    # End/terminate a contract
    # @param params [Hash] optional parameters (e.g., endDate, reason)
    # @return [self]
    def end_contract(params = {})
      Conexa::Request.post(self.class.show_url("end", primary_key), params: params).call(class_name)
      self
    end

    class << self
      # End a contract by ID
      # @param id [Integer, String] contract ID
      # @param params [Hash] optional parameters (e.g., endDate, reason)
      # @return [Contract]
      def end_contract(id, params = {})
        find(id).end_contract(params)
      end
    end
  end
end
