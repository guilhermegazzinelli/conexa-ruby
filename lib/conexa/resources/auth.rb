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
        Conexa::Request.auth('/auth', params: {
          username: username,
          password: password
        }).call('auth')
      end

      alias_method :authenticate, :login
    end

    # All attributes (user, token_type, access_token, expires_in) 
    # are accessible via method_missing
  end
end
