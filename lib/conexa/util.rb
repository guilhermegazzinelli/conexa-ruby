# frozen_string_literal: true

module Conexa
  class Util
    class << self

      SINGULARS = [
        [/(ss)$/i, '\1'],
        [/(n)ews$/i, '\1ews'],
        [/([ti])a$/i, '\1um'],
        [/((a)naly|(b)a|(d)iagno|(p)arenthe|(p)rogno|(s)ynop|(t)he)(sis|ses)$/i, '\1sis'],
        [/(^analy)(sis|ses)$/i, '\1sis'],
        [/([^f])ves$/i, '\1fe'],
        [/(hive)s$/i, '\1'],
        [/(tive)s$/i, '\1'],
        [/([lr])ves$/i, '\1f'],
        [/([^aeiouy]|qu)ies$/i, '\1y'],
        [/(s)eries$/i, '\1eries'],
        [/(m)ovies$/i, '\1ovie'],
        [/(x|ch|ss|sh)es$/i, '\1'],
        [/^(m|l)ice$/i, '\1ouse'],
        [/(bus)(es)?$/i, '\1'],
        [/(o)es$/i, '\1'],
        [/(shoe)s$/i, '\1'],
        [/(cris|test)(is|es)$/i, '\1is'],
        [/^(a)x[ie]s$/i, '\1xis'],
        [/(octop|vir)(us|i)$/i, '\1us'],
        [/(alias|status)(es)?$/i, '\1'],
        [/^(ox)en/i, '\1'],
        [/(vert|ind)ices$/i, '\1ex'],
        [/(matr)ices$/i, '\1ix'],
        [/(quiz)zes$/i, '\1'],
        [/(database)s$/i, '\1'],
        [/s$/i, '']
      ].freeze

      def singularize(resource)
        str = resource.to_s
        SINGULARS.each do |pattern, replacement|
          result = str.sub(pattern, replacement)
          return resource.is_a?(Symbol) ? result.to_sym : result if result != str
        end
        resource
      end

      def to_sym string
        string.to_s.strip.gsub(/[\s\-]+/, '_').to_sym
      end

      # Both "end" endpoints — PATCH /contract/end/:id and
      # PATCH /recurringSale/end/:id — document the closing date as `date`. The
      # gem used to send `end_date`, which camelizes to `endDate` and is rejected:
      # "endDate field does not exist or is not available in the company".
      #
      # @param params [Hash] caller params, possibly using the old name
      # @return [Hash] a copy with :end_date folded into :date
      def normalize_end_date_param(params)
        params = params.dup
        legacy = params.delete(:end_date)
        legacy = params.delete("end_date") || legacy
        return params unless legacy

        warn "DEPRECATION WARNING: `end_date:` foi renomeado para `date:` em conexa 0.2.0 " \
             "(a API v2 rejeita `endDate`). O alias será removido em 0.3.0."
        params[:date] ||= legacy
        params
      end

      def to_snake_case str
        str.gsub(/([A-Z])/, '_\1').downcase.sub(/^_/, '')
      end


      # Convert a payload's keys to the camelCase the API expects, all the way
      # down. Arrays of objects matter as much as nested hashes: ten documented
      # endpoints take them (complementaryServices, productQuotas, devices,
      # extraFields, bookingModels, visitors, costCenters, ...), and a snake_case
      # key inside one is rejected outright.
      def camelize_hash(hash)
        return {} if hash.nil?

        hash.each_with_object({}) do |(key, value), new_hash|
          new_hash[camel_case_lower(key).to_sym] = camelize_value(value)
        end
      end

      def camelize_value(value)
        case value
        when Hash  then camelize_hash(value)
        when Array then value.map { |element| camelize_value(element) }
        else value
        end
      end

      def camelize_str(str)
        str.to_s.gsub(/_([a-z0-9])/) {  Regexp.last_match[1].upcase }
      end

      def camel_case_lower str
        str.to_s.split('_').inject([]){ |buffer,e| buffer.push(buffer.empty? ? e : e.capitalize) }.join
      end

    end
  end
end
