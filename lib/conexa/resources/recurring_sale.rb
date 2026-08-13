# frozen_string_literal: true

module Conexa
  class RecurringSale < Model
    primary_key_attribute :recurring_sale_id

    # Set this recurring sale's end date — closing it, or amending an existing
    # closure.
    #
    # Like the contract endpoint, this one is documented as "encerra uma venda
    # recorrente ativa **ou atualiza a data de encerramento**".
    #
    # @param params [Hash]
    # @option params [String] :date required, yyyy-MM-dd — the closing date
    # @option params [String] :end_date deprecated alias for +:date+; the API
    #   rejects the +endDate+ it camelizes to
    # @return [self]
    def end_recurring_sale(params = {})
      params = Util.normalize_end_date_param(params)
      Conexa::Request.patch(self.class.show_url("end", primary_key), params: params).call(class_name)
      self
    end
    alias_method :set_end_date, :end_recurring_sale

    class << self
      def url(*params)
        ["/recurringSales", *params].join '/'
      end

      def show_url(*params)
        ["/recurringSale", *params].join '/'
      end

      # Set a recurring sale's end date by ID
      # @see #end_recurring_sale
      # @param id [Integer, String] recurring sale ID
      # @return [RecurringSale]
      def end_recurring_sale(id, params = {})
        find(id).end_recurring_sale(params)
      end
      alias_method :set_end_date, :end_recurring_sale
    end
  end
end
