# frozen_string_literal: true

module Conexa
  class Configuration
    # @return [String] the Application Token, created in Conexa under
    #   Config > Integrações > API / Token
    attr_accessor :api_token

    # @return [String] the tenant base URL, e.g. "https://mycompany.conexa.app"
    attr_accessor :api_host

    # Set to force read-only mode on or off, overriding the environment.
    # @return [Boolean]
    attr_writer :read_only

    # Values that turn read-only mode on via CONEXA_READ_ONLY.
    TRUTHY = %w[1 true yes on].freeze

    # Values that explicitly turn it off. Anything else is a typo worth warning
    # about — silently failing open on `CONEXA_READ_ONLY=treu` would leave an
    # operator believing writes were blocked when they are not.
    FALSEY = %w[0 false no off].freeze

    def initialize
      @api_token = ''
      @api_host = ''
      @read_only = nil
    end

    # When true, any request other than GET raises {Conexa::ReadOnlyError} before
    # reaching the network.
    #
    # Read lazily so that CONEXA_READ_ONLY still applies when it is set after
    # {Conexa.configure} has run — it used to be captured once at initialization,
    # which made setting it later a silent no-op. An explicit assignment always
    # wins over the environment.
    #
    # @return [Boolean]
    def read_only
      return @read_only unless @read_only.nil?

      env_read_only
    end

    private

    def env_read_only
      value = ENV["CONEXA_READ_ONLY"].to_s.strip.downcase
      return false if value.empty?
      return true  if TRUTHY.include?(value)
      return false if FALSEY.include?(value)

      warn "Conexa: CONEXA_READ_ONLY=#{value.inspect} não é reconhecido e foi ignorado " \
           "(modo somente-leitura DESLIGADO). Use um de: #{(TRUTHY + FALSEY).join(", ")}."
      false
    end
  end
end
