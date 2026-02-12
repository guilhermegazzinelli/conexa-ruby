# frozen_string_literal: true

module Conexa
  # Authentication resource for username/password authentication
  # 
  # @example Authenticate with credentials
  #   auth = Conexa::Auth.login(username: 'admin', password: 'secret')
  #   auth.access_token  # => "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
  #   auth.expires_in    # => 28800
  #
  # @note For most cases, use Application Token instead (configured in Conexa.configure)
  class Auth < ConexaObject
    class << self
      # Authenticate with username and password
      # 
      # @param username [String] Login username (admin or employee email)
      # @param password [String] Password
      # @return [Auth] Authentication result with access_token
      # @raise [Conexa::AuthenticationError] if credentials are invalid
      #
      # @example
      #   auth = Conexa::Auth.login(username: 'admin', password: 'mypassword')
      #   # Use the token for subsequent requests
      #   Conexa.configure { |c| c.api_token = auth.access_token }
      def login(username:, password:)
        response = Conexa::Request.post('/auth', params: {
          username: username,
          password: password
        }).call('auth')
        
        new(response.to_h)
      end

      alias_method :authenticate, :login
    end

    # @return [Hash] User object with id, type, and name
    def user
      @attributes['user']
    end

    # @return [String] Token type (always "Bearer")
    def token_type
      @attributes['token_type']
    end
    alias_method :tokenType, :token_type

    # @return [String] JWT access token
    def access_token
      @attributes['access_token']
    end
    alias_method :accessToken, :access_token

    # @return [Integer] Token expiration time in seconds
    def expires_in
      @attributes['expires_in']
    end
    alias_method :expiresIn, :expires_in
  end
end
