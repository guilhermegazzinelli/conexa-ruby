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

    def run
      response = RestClient::Request.execute request_params

      response = MultiJson.decode response.body
      response.dig("data") || response


      rescue RestClient::Exception => error
        begin
          parsed_error = MultiJson.decode error.http_body

          if error.is_a? RestClient::ResourceNotFound
            if parsed_error['message']
              raise Conexa::NotFound.new(parsed_error, request_params, error)
            else
              raise Conexa::NotFound.new(nil, request_params, error)
            end
          else
            if parsed_error['message']
              raise Conexa::ResponseError.new(request_params, error, parsed_error['message'] + "=> Erros: "+ parsed_error['errors'].to_s)
            else
              raise Conexa::ValidationError.new parsed_error
            end
          end
        rescue MultiJson::ParseError
          raise Conexa::ResponseError.new(request_params, error)
        end
      rescue MultiJson::ParseError
        return {} if response.code == 204

        raise Conexa::ResponseError.new(request_params, response)
      rescue SocketError
        raise Conexa::ConnectionError.new $!
      rescue RestClient::ServerBrokeConnection
        raise Conexa::ConnectionError.new $!
    end

    def call(ressource_name)
      ConexaObject.convert run, ressource_name
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

      extra_headers = DEFAULT_HEADERS
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

      url
    end
  end
end
