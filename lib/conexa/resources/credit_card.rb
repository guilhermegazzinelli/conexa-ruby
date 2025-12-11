module Conexa
  class CreditCard < Model
    class << self
      def url(*params)
        ["/creditCard", *params].join '/'
      end

      def show_url(*params)
        ["/creditCard", *params].join '/'
      end
    end
  end
end
