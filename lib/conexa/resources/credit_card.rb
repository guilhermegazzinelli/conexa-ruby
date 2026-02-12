module Conexa
  class CreditCard < Model
    primary_key_attribute :credit_card_id

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
