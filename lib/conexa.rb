# frozen_string_literal: true

require_relative "conexa/version"
require_relative "conexa/authenticator"
require_relative "conexa/request"
require_relative "conexa/object"
require_relative "conexa/model"
require_relative "conexa/core_ext"
require_relative "conexa/errors"
require_relative "conexa/util"
require_relative "conexa/configuration"
require_relative "conexa/order_commom"


Dir[File.expand_path('../conexa/resources/*.rb', __FILE__)].map do |path|
  require path
end

module Conexa
  class Error < StandardError; end

  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  def self.api_endpoint
    configuration.api_host + "/index.php/api/v2"
  end
end
