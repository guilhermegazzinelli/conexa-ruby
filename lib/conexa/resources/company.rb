# frozen_string_literal: true

module Conexa
  # Company resource (Empresa / unidade)
  #
  # @example List companies
  #   Conexa::Company.all(limit: 50)
  #
  # @example Find a company
  #   Conexa::Company.find(3)
  class Company < Model
    class << self
      # Model#url pluralizes by appending "s", which yields "/companys" and 404s.
      # Any resource with an irregular English plural has to override this — see
      # spec/contract/api_contract_spec.rb, which checks every resource's URL
      # against the published collection.
      def url(*params)
        ["/companies", *params].join '/'
      end

      def show_url(*params)
        ["/company", *params].join '/'
      end
    end
  end
end
