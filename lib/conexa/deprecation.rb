# frozen_string_literal: true

module Conexa
  # Emits each deprecation once per process.
  #
  # The warnings exist to be read once and acted on. Emitting per call turns them
  # into noise a caller learns to filter — `charges.select(&:pending?)` over one
  # page of results produced a hundred identical lines, which is how a warning
  # stops being read.
  module Deprecation
    @seen  = {}
    @mutex = Mutex.new

    class << self
      # @param key [Object] identifies the deprecation, not the call site
      # @param message [String] what changed and what to do instead
      # @return [nil]
      def warn_once(key, message)
        @mutex.synchronize do
          return nil if @seen[key]

          @seen[key] = true
        end

        Kernel.warn("DEPRECATION WARNING: #{message}")
        nil
      end

      # Only for tests: lets a spec observe a warning that another example
      # already consumed.
      # @api private
      def reset!
        @mutex.synchronize { @seen = {} }
      end
    end
  end

  # Mixed into the classes that carry deprecated methods.
  module Deprecatable
    def deprecate(key, message)
      Deprecation.warn_once([self, key], message)
    end
  end
end
