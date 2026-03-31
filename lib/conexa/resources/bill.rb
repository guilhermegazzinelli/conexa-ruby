# frozen_string_literal: true

module Conexa
  class Bill  < Model
    def save
      raise NoMethodError, "Bill does not support save"
    end
  end
end
