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
      # Both key spellings are handled, and both are removed. Checking only the
      # symbol `:date` would leave a caller's string `"date"` in place and add a
      # second, colliding key — camelize_hash folds the two into one and the last
      # one wins, so the deprecated value would silently replace the real one.
      #
      # @param params [Hash] caller params, possibly using the old name
      # @return [Hash] a copy with end_date folded into date
      def normalize_end_date_param(params)
        params = params.dup

        # Collapse both spellings of each key up front. Leaving one behind would
        # let camelize_hash fold two `date` keys into one, last-write-wins — which
        # is how the deprecated value once silently replaced the real one.
        legacy   = [params.delete(:end_date), params.delete("end_date")].compact.first
        explicit = [params.delete(:date), params.delete("date")].compact.first

        warn_end_date_renamed if legacy

        # An explicit date wins; a key present with a nil value is not one.
        date = explicit || legacy
        params[:date] = date unless date.nil?
        params
      end

      # Renames listing filters the API v2 stopped accepting (it answers 400
      # "field does not exist or is not available in the company"), so callers
      # still using the old names keep working until 0.3.0.
      #
      # Only for listing params. `start_date` & co. are legitimate fields in
      # create/update payloads, which must never go through here.
      #
      # Same rules as {normalize_end_date_param}: every spelling of a key is
      # collected and removed before camelize_hash (no colliding keys); an
      # explicit new name wins; a key present with a nil value is not a value.
      # A spelling is snake_case or camelCase, with or without a trailing `[]`,
      # as a Symbol or a String.
      #
      # @param params [Hash] caller params (not mutated)
      # @param renames [Hash{Symbol=>Symbol}] legacy name => current name
      # @param resource [String] resource label, used in the warning
      # @param arrays [Array<Symbol>] current names whose value is always sent
      #   as an array (`name[]=...`), however the caller wrote it
      # @return [Hash] a copy with the legacy names folded into the current ones
      def normalize_list_params(params, renames, resource:, arrays: [])
        params = params.dup

        renames.each do |legacy_name, current_name|
          legacy   = take_param(params, legacy_name)
          explicit = take_param(params, current_name)

          warn_list_param_renamed(resource, legacy_name, current_name) unless legacy.nil?

          value = explicit.nil? ? legacy : explicit
          next if value.nil?

          params[current_name] = arrays.include?(current_name) ? Array(value) : value
        end

        params
      end

      # Removes every spelling of a key, returns the first non-nil value found.
      def take_param(params, name)
        keys = [name.to_s, camelize_str(name)].uniq.flat_map { |key| [key, "#{key}[]"] }
        keys.flat_map { |key| [params.delete(key.to_sym), params.delete(key)] }.compact.first
      end

      def warn_list_param_renamed(resource, legacy_name, current_name)
        Deprecation.warn_once([:list_param, resource, legacy_name],
                              "`#{legacy_name}:` em #{resource}.all/where/find_by foi renomeado para " \
                              "`#{current_name}:` (a API v2 rejeita o nome antigo com 400). " \
                              "O alias será removido em 0.3.0.")
      end

      def to_snake_case str
        str.gsub(/([A-Z])/, '_\1').downcase.sub(/^_/, '')
      end


      def warn_end_date_renamed
        Deprecation.warn_once(:end_date_param,
                              "`end_date:` foi renomeado para `date:` em conexa 0.2.0 " \
                              "(a API v2 rejeita `endDate`). O alias será removido em 0.3.0.")
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
