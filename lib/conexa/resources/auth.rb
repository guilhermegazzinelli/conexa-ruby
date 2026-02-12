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

      # DSL for Auth attributes (not a Model, so define here)
      def attribute(snake_name)
        camel_name = Util.camelize_str(snake_name.to_s)

        define_method(snake_name) do
          @attributes[snake_name.to_s]
        end

        alias_method camel_name.to_sym, snake_name
      end
    end

    attribute :user
    attribute :token_type
    attribute :access_token
    attribute :expires_in
  end
end
