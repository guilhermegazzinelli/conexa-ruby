module Conexa
  class Supplier < Model
    class << self
      def url(*params)
        ["/supplier", *params].join '/'
      end

      def show_url(*params)
        ["/supplier", *params].join '/'
      end
    end
  end
end
