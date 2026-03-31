# frozen_string_literal: true

# Only define blank?/present? if not already provided (e.g., by ActiveSupport)
unless Object.method_defined?(:blank?)
  class Object
    def blank?
      respond_to?(:empty?) ? !!empty? : !self
    end

    def present?
      !blank?
    end
  end
end
