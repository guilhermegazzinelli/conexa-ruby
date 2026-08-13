# frozen_string_literal: true

require_relative "conexa/version"
# No dependencies of its own, and Model extends it at load time.
require_relative "conexa/deprecation"
require_relative "conexa/request"
require_relative "conexa/object"
require_relative "conexa/model"
require_relative "conexa/core_ext"
require_relative "conexa/errors"
require_relative "conexa/util"
require_relative "conexa/configuration"


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

  # Key for the block-scoped read-only override. Thread-local so a guarded block
  # in one thread cannot relax or tighten another.
  READ_ONLY_KEY = :conexa_read_only

  # Is writing currently forbidden?
  #
  # True inside a {read_only} block, or whenever `configuration.read_only` is set
  # (which itself defaults from CONEXA_READ_ONLY).
  #
  # @return [Boolean]
  def self.read_only?
    scoped = Thread.current[READ_ONLY_KEY]
    return scoped unless scoped.nil?

    !!configuration&.read_only
  end

  # Run a block with writes forbidden, then restore the previous state.
  #
  # Useful for auditing or reporting code that should never mutate a tenant,
  # without having to reconfigure the client globally.
  #
  # @example
  #   Conexa.read_only do
  #     Conexa::Charge.all(status: "pending")   # fine
  #     Conexa::Charge.settle(555)              # raises Conexa::ReadOnlyError
  #   end
  #
  # @param enabled [Boolean] pass false to explicitly allow writes in the block
  # @return [Object] the block's return value
  def self.read_only(enabled = true)
    previous = Thread.current[READ_ONLY_KEY]
    Thread.current[READ_ONLY_KEY] = enabled
    yield
  ensure
    Thread.current[READ_ONLY_KEY] = previous
  end
end
