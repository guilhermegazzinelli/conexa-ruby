require 'jwt'


module Conexa
  # Valid client types for authentication
  CLIENT_TYPES = [:pdv, :e_comerce].freeze
  #
  # Class to hold client authetication data
  #
  class Client
    attr_reader :secret_key, :access_key, :client_id, :key, :type
    attr_accessor :default


    #
    # Initialize Client instance
    #
    # @param [Hash] **options Options required
    # @options [String] :secret_key (Defaults to Conexa.secret_key)
    # @options [String] :access_key (Defaults to Conexa.access_key)
    # @options [String] :client_id (Required) The client identifier
    # @options [String] :key (Defaults to Conexa.default_client_key)
    # @options [Boolean] :default (Defaults to true) Param to define if client is the default one ( Not fully used)
    # @options [Symbol] :type (Defaults to :pdv) Param to define if client is an PDV or E-Commerce [:pdv, :e_comerce]. Raises ParamError if not included in these types.
    def initialize(**options)
      begin
        @secret_key = options.fetch(:secret_key, Conexa.secret_key)
        @access_key = options.fetch(:access_key, Conexa.access_key)
        @client_id = options.fetch(:client_id)
        @key = Conexa::Util.to_sym(options.fetch(:key, Conexa.default_client_key ))
        @default = options.fetch(:default, true)
        @type = options.fetch(:type, :pdv)
        raise ParamError.new("Incorrect client type, must be one of #{CLIENT_TYPES}", :type, "Symbol") unless CLIENT_TYPES.include? @type
      rescue KeyError => e
        raise ParamError.new("Missing data for credentials: #{e.key}, (#{e.message})", "Credentials", "Symbol or String") unless CLIENT_TYPES.include? @type
      end
    end

    #
    # Convert Client instance to hash
    #
    # @return [Hash] Return Client in hash form
    #
    def to_h
      {
        secret_key: @secret_key,
        access_key: @access_key,
        client_id: @client_id,
        key: @key
      }
    end
  end

  class Authenticator
    attr_reader :key, :client

    #
    # Initialize Authenticator Class
    #
    # @param [Client] client Receives Client instance to initialize authenticator
    #
    def initialize(client)
      @client = client
      @key = client.key
      authenticate
    end

    #
    # Return client authentication token
    #
    # @return [String] Returns cleint authentication token
    #
    def token
      refresh_token_if_expired
      @a_token
    end

    private

    #
    # Call api to authenticate client, receiving auth and refresh token
    #
    # @return [String] Refresh token
    #
    def authenticate
      set_token_from_request Conexa::Request.auth('/pdvauth', {params: {client_id: @client.client_id, secret_key: @client.secret_key, access_key: @client.access_key, client_key: @key}}).run
    end

    #
    # Refreshes token to receive a new, not expired, JWT auth_token
    #
    # @return [<Type>] <description>
    #
    def refresh_token
      set_token_from_request Conexa::Request.auth('/refresh-token', {headers:   {  authorization: 'Bearer ' + @r_token}, client_key: @key}).run
    end

    def refresh_token_if_expired
      refresh_token if Time.at(JWT.decode(@a_token, nil, false).first.dig('exp')) < Time.now()
    end

    #
    # Sets tokens based on response of request
    #
    # @param [ConexaObject] response Response from authentication or refresh request
    # @note Must include 'access_token' and 'refresh_token'
    # @return [String] Refresh token
    #
    def set_token_from_request response
      @a_token = response['access_token']
      @r_token = response['refresh_token']
    end
  end
end
