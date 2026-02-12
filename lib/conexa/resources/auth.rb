# frozen_string_literal: true

module Conexa
  # Authentication resource for username/password authentication
  # 
  # @example Authenticate with credentials
  #   auth = Conexa::Auth.login(username: 'admin', password: 'secret')
  #   auth.accessToken  # => "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
  #   auth.expiresIn    # => 28800
  #
  # @note For most cases, use Application Token instead (configured in Conexa.configure)
  class Auth < ConexaObject
    class << self
      # Authenticate with username and password
      # 
      # @param username [String] Login username (admin or employee email)
      # @param password [String] Password
      # @return [Auth] Authentication result with accessToken
      # @raise [Conexa::AuthenticationError] if credentials are invalid
      #
      # @example
      #   auth = Conexa::Auth.login(username: 'admin', password: 'mypassword')
      #   # Use the token for subsequent requests
      #   Conexa.configure { |c| c.api_token = auth.accessToken }
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
    def tokenType
      @attributes['tokenType']
    end

    # @return [String] JWT access token
    def accessToken
      @attributes['accessToken']
    end

    # @return [Integer] Token expiration time in seconds
    def expiresIn
      @attributes['expiresIn']
    end
  end
end
