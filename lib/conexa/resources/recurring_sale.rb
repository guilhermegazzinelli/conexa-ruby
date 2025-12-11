module Conexa
  class RecurringSale < Model
    # End/terminate a recurring sale
    # @param params [Hash] optional parameters (e.g., endDate)
    # @return [self]
    def end_recurring_sale(params = {})
      Conexa::Request.post(self.class.show_url("end", primary_key), params: params).call(class_name)
      self
    end

    class << self
      def url(*params)
        ["/recurringSales", *params].join '/'
      end

      def show_url(*params)
        ["/recurringSale", *params].join '/'
      end

      # End a recurring sale by ID
      # @param id [Integer, String] recurring sale ID
      # @param params [Hash] optional parameters (e.g., endDate)
      # @return [RecurringSale]
      def end_recurring_sale(id, params = {})
        find(id).end_recurring_sale(params)
      end
    end
  end
end
