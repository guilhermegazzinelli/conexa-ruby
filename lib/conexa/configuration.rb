module Conexa
  class Configuration
    attr_accessor :api_token, :api_host

    def initialize
      @api_token = ''
      @api_host = ''
    end
  end
end