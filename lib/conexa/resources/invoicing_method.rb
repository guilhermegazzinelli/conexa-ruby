module Conexa
  class InvoicingMethod < Model
    class << self
      def url(*params)
        ["/invoicingMethods", *params].join '/'
      end

      def show_url(*params)
        ["/invoicingMethod", *params].join '/'
      end
    end
  end
end
