# frozen_string_literal: true

module Conexa
  class Configuration
    # @return [String] the Application Token, created in Conexa under
    #   Config > Integrações > API / Token
    attr_accessor :api_token

    # @return [String] the tenant base URL, e.g. "https://mycompany.conexa.app"
    attr_accessor :api_host

    # @return [Boolean] when true, any request other than GET raises
    #   {Conexa::ReadOnlyError} before reaching the network. Defaults from the
    #   CONEXA_READ_ONLY environment variable.
    attr_accessor :read_only

    # Values that turn read-only mode on via CONEXA_READ_ONLY.
    TRUTHY = %w[1 true yes on].freeze

    def initialize
      @api_token = ''
      @api_host = ''
      @read_only = TRUTHY.include?(ENV["CONEXA_READ_ONLY"].to_s.strip.downcase)
    end
  end
end
