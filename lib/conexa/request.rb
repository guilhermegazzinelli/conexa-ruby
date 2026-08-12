# frozen_string_literal: true

require 'uri'
require 'rest_client'
require 'multi_json'

module Conexa
  class Request
    DEFAULT_HEADERS = {
      'Content-Type' => 'application/json; charset=utf8',
      'Accept'       => 'application/json',
      'User-Agent'   => "conexa-ruby/#{Conexa::VERSION}"
    }

    attr_accessor :path, :method, :parameters, :headers, :query

    def initialize(path, method, options={})
        @path       = path
        @method     = method
        @parameters = options[:params]      || nil
        @query      = options[:query]       || Hash.new
        @headers    = options[:headers]     || Hash.new
        @auth       = options[:auth]        || false
    end

    # Verbs allowed while Conexa.read_only? — GET, plus authentication, without
    # which read-only mode could not obtain a token in the first place.
    READ_METHODS = %w(GET).freeze

    # The authentication exemption is tied to these paths, not to the caller's
    # `auth:` flag. `Request.auth` is public, so trusting the flag alone let any
    # write opt out of the guard with `Request.auth("/charge/settle/1", …)`.
    AUTH_PATHS = %w(/auth).freeze

    def run
      enforce_read_only!

      response = RestClient::Request.execute request_params

      # A successful write may answer with no body at all: PATCH /charge/settle/:id
      # documents 204 + empty body as its success response, and
      # PATCH /contract/end/:id answers 200 with one. With the Oj adapter,
      # MultiJson.decode("") returns nil *without* raising ParseError, so the
      # nil has to be caught here rather than in a rescue.
      body = response.body.to_s
      return {} if body.strip.empty?

      decoded = MultiJson.decode(body)
      return {} if decoded.nil?

      # A top-level array (some list endpoints) has no #dig(String).
      return {data: decoded, pagination: nil} unless decoded.is_a?(Hash)

      {data: decoded["data"] || decoded, pagination: decoded["pagination"]}

      # Connection-level failures first. These subclass RestClient::Exception, so
      # listing them after it made them unreachable — Ruby matches rescue clauses
      # top-down. The broad clause then tried to decode their (nil) http_body and
      # raised NoMethodError instead of the documented ConnectionError.
      #
      # All of these carry no response, so there is nothing to classify: they are
      # failures to reach the API, not answers from it. Note that a real HTTP 408
      # is RestClient::RequestTimeout, a *superclass* of Exceptions::Timeout, so
      # it correctly stays in the response taxonomy below.
      rescue SocketError, RestClient::ServerBrokeConnection,
             RestClient::SSLCertificateNotVerified,
             RestClient::Exceptions::Timeout => error
        raise Conexa::ConnectionError.new error
      rescue RestClient::Exception => error
        begin
          # nil for an error carrying no body; MultiJson.decode(nil) returns nil
          # rather than raising, so the guard has to be here. An error body that
          # decodes to an array or a scalar has no #[](String) either, and used
          # to raise TypeError from inside this handler.
          parsed_error = MultiJson.decode(error.http_body.to_s)
          parsed_error = {} unless parsed_error.is_a?(Hash)

          if error.is_a? RestClient::ResourceNotFound
            if parsed_error['message']
              raise Conexa::NotFound.new(parsed_error, request_params, error)
            else
              raise Conexa::NotFound.new(nil, request_params, error)
            end
          else
            if parsed_error['message']
              raise Conexa::ResponseError.new(request_params, error,
                                              describe_api_error(parsed_error), parsed_error)
            else
              raise Conexa::ValidationError.new parsed_error
            end
          end
        rescue MultiJson::ParseError
          raise Conexa::ResponseError.new(request_params, error)
        end
      rescue MultiJson::ParseError
        # Only genuinely malformed JSON reaches here — empty and null bodies are
        # handled above, for every status.
        raise Conexa::ResponseError.new(request_params, response)
    end

    # The API's `message` plus its `errors`, rendered as prose.
    #
    # This used to be `message + "=> Erros: " + errors.to_s`, which appended a
    # dangling "=> Erros: " to the 75 documented responses that carry no `errors`
    # array, and dumped Ruby's `#inspect` of an array of hashes for the ones that
    # do. ResponseError#api_error_messages already normalises both shapes.
    def describe_api_error(parsed_error)
      message = parsed_error['message'].to_s
      details = Conexa::ResponseError.new({}, nil, nil, parsed_error).api_error_messages
      return message if details.empty?

      "#{message} — #{details.join("; ")}"
    end

    # @raise [Conexa::ReadOnlyError] when a mutating verb is attempted while
    #   Conexa.read_only? — checked before the request is executed, so nothing
    #   reaches the tenant.
    def enforce_read_only!
      return unless Conexa.read_only?
      return if READ_METHODS.include?(method.to_s.upcase)
      return if @auth && AUTH_PATHS.include?(path)

      # Deliberately `path`, not `full_api_url`: the latter validates the URL and
      # can raise RequestError, which would win over this one purely because the
      # message is interpolated first. Read-only is a policy — it applies whatever
      # the path looks like.
      raise Conexa::ReadOnlyError,
            "Conexa is in read-only mode: refusing #{method.to_s.upcase} #{path}. " \
            "Unset config.read_only (or CONEXA_READ_ONLY) to allow writes."
    end

    def call(resource_name, query_context: nil)
      dt = run

      if dt[:pagination]
        result = ConexaObject.convert({
          data: ConexaObject.convert(dt[:data], resource_name),
          pagination: ConexaObject.convert(dt[:pagination], "pagination")}, "result")
        result.instance_variable_set(:@query_context, query_context) if query_context
        return result
      end

      ConexaObject.convert(dt[:data], resource_name)
    end

    def self.get(url, options={})
      self.new url, 'GET', options
    end

    def self.auth(url, options={})
      options[:auth] = true
      self.new url, 'POST', options
    end

    def self.post(url, options={})
      self.new url, 'POST', options
    end

    def self.put(url, options={})
      self.new url, 'PUT', options
    end

    def self.patch(url, options={})
      self.new url, 'PATCH', options
    end

    def self.delete(url, options={})
      self.new url, 'DELETE', options
    end

    def request_params
      aux = {
        method:       method,
        url:          full_api_url,
      }
      @parameters = Util.camelize_hash(@parameters)
      aux.merge!({ payload:   MultiJson.encode(@parameters)}) unless %w(GET DELETE).include? method

      extra_headers = DEFAULT_HEADERS.dup
      extra_headers[:authorization] = "Bearer #{Conexa.configuration.api_token}" unless @auth
      extra_headers[:params] = @parameters if method == "GET"
      aux.merge!({ headers: extra_headers })
      aux
    end

    def full_api_url
      url = Conexa.api_endpoint + path

      if @query.present?
        url += '?' + URI.encode_www_form(query)
      end

      # An unusable path (a stray space in an id, say) would otherwise surface as
      # URI::InvalidURIError from inside RestClient — outside Conexa::ConexaError,
      # so no caller could rescue it meaningfully.
      begin
        URI.parse(url)
      rescue URI::InvalidURIError
        raise Conexa::RequestError, "Invalid request path: #{path.inspect}"
      end

      url
    end
  end
end
