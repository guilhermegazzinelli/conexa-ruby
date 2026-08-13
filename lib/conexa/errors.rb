# frozen_string_literal: true

module Conexa
  class ConexaError < StandardError
  end

  class ConnectionError < ConexaError
    attr_reader :error

    def initialize(error)
      @error = error
      super error.message
    end
  end

  class RequestError < ConexaError
  end

  # Raised instead of performing a mutating request while Conexa.read_only?.
  # The request never reaches the network.
  class ReadOnlyError < ConexaError
  end

  class ResponseError < ConexaError
    attr_reader :request_params, :error

    # The decoded error body, when the API returned one.
    # @return [Hash]
    attr_reader :api_response

    def initialize(request_params, error, message=nil, api_response=nil)
      @request_params, @error = request_params, error
      @api_response = api_response.is_a?(Hash) ? api_response : {}
      msg = describe_error(error)
      msg +=  " => " + message if message
      super msg
    end

    # The API's errors, normalised across its two shapes.
    #
    # Field validation answers `{"field": …, "messages": [...]}`; business rules
    # answer `{"code": …, "message": …}`. Consumers that only handled the first
    # rendered business-rule errors as blank strings — which is how
    # CONTRACT_RECURRING_SALE_10 stayed invisible through eight attempts.
    #
    # @return [Array<Hash{Symbol=>String,nil}>] entries of {field:, code:, message:}
    def api_errors
      Array(api_response["errors"]).filter_map do |entry|
        next unless entry.is_a?(Hash)

        { field:   entry["field"],
          code:    entry["code"],
          message: entry["message"] || Array(entry["messages"]).join("; ") }
      end
    end

    # Documented business-rule codes, e.g. "CHARGE_11" or
    # "CONTRACT_RECURRING_SALE_10". These are what a caller branches on — for
    # instance to tell an already-settled charge from a real settlement failure.
    #
    # @return [Array<String>]
    def api_error_codes
      api_errors.filter_map { |entry| entry[:code] }
    end

    # One readable line per error, whichever shape it arrived in.
    # @return [Array<String>]
    def api_error_messages
      api_errors.map do |entry|
        label = entry[:field] || entry[:code]
        label ? "#{label}: #{entry[:message]}" : entry[:message]
      end
    end

    private

    # `error` is usually a RestClient::Exception, but the malformed-body path
    # hands us a RestClient::Response, which has no #message — that used to raise
    # NoMethodError from inside the error constructor itself.
    def describe_error(error)
      return error.message if error.respond_to?(:message) && error.message
      return "HTTP #{error.code}: #{error.body.to_s[0, 200]}" if error.respond_to?(:code)

      error.to_s
    end
  end

  class NotFound < ResponseError
    attr_reader :response
    def initialize(response, request_params, error)
      @response = response
      super request_params, error, response&.dig('message'), response
    end
  end

  # Raised for an error body with no `message` key.
  #
  # Every error response the published collection documents carries a `message`,
  # so in practice this is reached only by an undocumented or malformed body. It
  # used to render as the bare string "Conexa::ValidationError" and `#to_h` raised
  # NoMethodError; both now degrade to something a caller can act on.
  class ValidationError < ConexaError
    attr_reader :response, :errors

    def initialize(response)
      @response = response
      @errors   = Array(response.is_a?(Hash) ? response['message'] : nil).filter_map do |msg|
        next unless msg.is_a?(Hash)

        ParamError.new(*msg.values_at('message', 'parameter_name', 'type', 'url'))
      end

      super(@errors.any? ? @errors.map(&:message).join(', ') : describe(response))
    end

    def to_h
      @errors.map(&:to_h)
    end

    private

    def describe(response)
      "The API returned an error with no message: #{response.inspect[0, 200]}"
    end
  end

  class MissingCredentialsError < ConexaError
  end


  class ParamError < ConexaError
    attr_reader :parameter_name, :type, :url

    def initialize(message, parameter_name, type, url=nil)
      @parameter_name, @type, @url = parameter_name, type, url
      super message
    end

    def to_h
      { parameter_name: parameter_name, type: type, message: message }
    end
  end
end
