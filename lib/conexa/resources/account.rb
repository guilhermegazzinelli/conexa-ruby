# frozen_string_literal: true

module Conexa
  # Account resource (Conta Bancária)
  #
  # @example Find an account
  #   account = Conexa::Account.find(23)
  #   account.name  # => "Banco do Brasil"
  #
  # @example List accounts
  #   accounts = Conexa::Account.all(limit: 50)
  #
  # @!attribute [r] account_id
  #   @return [Integer] Account ID (also accessible as #id)
  # @!attribute [r] name
  #   @return [String] Account name
  # @!attribute [r] is_active
  #   @return [Boolean] Whether the account is active
  #
  class Account < Model
    primary_key_attribute :account_id

    class << self
      def url(*params)
        ["/accounts", *params].join '/'
      end

      def show_url(*params)
        ["/account", *params].join '/'
      end
    end
  end
end
