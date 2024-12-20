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

  class ResponseError < ConexaError
    attr_reader :request_params, :error

    def initialize(request_params, error, message=nil)
      @request_params, @error = request_params, error
      msg = @error.message
      msg +=  " => " + message if message
      super msg
    end
  end

  class NotFound < ResponseError
    attr_reader :response
    def initialize(response, request_params, error)
      @response = response
      super request_params, error, response&.dig('message')
    end
  end

  class ValidationError < ConexaError
    attr_reader :response, :errors

    def initialize(response)
      @response = response
      @errors   = response['message']&.map do |message|
        params = error.values_at('message', 'parameter_name', 'type', 'url')
        ParamError.new(*params)
      end
      super @errors&.map(&:message).join(', ')
    end

    def to_h
      @errors.map(&:to_h)
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
