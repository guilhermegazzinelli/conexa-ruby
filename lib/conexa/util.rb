module Conexa
  class Util
    class << self

      SINGULARS = {
        '/s$/i' => "",
        '/(ss)$/i' => '\1',
        '/(n)ews$/i' => '\1ews',
        '/([ti])a$/i' => '\1um',
        '/((a)naly|(b)a|(d)iagno|(p)arenthe|(p)rogno|(s)ynop|(t)he)(sis|ses)$/i' => '\1sis',
        '/(^analy)(sis|ses)$/i' => '\1sis',
        '/([^f])ves$/i' => '\1fe',
        '/(hive)s$/i' => '\1',
        '/(tive)s$/i' => '\1',
        '/([lr])ves$/i' => '\1f',
        '/([^aeiouy]|qu)ies$/i' => '\1y',
        '/(s)eries$/i' => '\1eries',
        '/(m)ovies$/i' => '\1ovie',
        '/(x|ch|ss|sh)es$/i' => '\1',
        '/^(m|l)ice$/i' => '\1ouse',-
        '/(bus)(es)?$/i' => '\1',
        '/(o)es$/i' => '\1',
        '/(shoe)s$/i' => '\1',
        '/(cris|test)(is|es)$/i' => '\1is',
        '/^(a)x[ie]s$/i' => '\1xis',
        '/(octop|vir)(us|i)$/i' => '\1us',
        '/(alias|status)(es)?$/i' => '\1',
        '/^(ox)en/i' => '\1',
        '/(vert|ind)ices$/i' => '\1ex',
        '/(matr)ices$/i' => '\1ix',
        '/(quiz)zes$/i' => '\1',
        '/(database)s$/i' => '\1'}

      def singularize resource
        out = ''
        SINGULARS.keys.each do |key|
          out = resource.to_s.gsub(/s$/,SINGULARS[key])
          break out if out != resource
        end

        resource.is_a?(Symbol) ? out.to_sym : out
      end

      def to_sym string
        string.to_s.strip.gsub(/[\s\-]+/, '_').to_sym
      end

      def to_snake_case str
        str.gsub(/([A-Z])/, '_\1').downcase.sub(/^_/, '')
      end


      def camelize_hash(hash)
        new_hash = {}

        hash.each do |key, value|
          if value.is_a?(Hash)
            new_hash[camel_case_lower(key).to_sym] = camelize_hash(value)
          else
            new_hash[camel_case_lower(key).to_sym] = value
          end
        end

        new_hash
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

class Hash
  def except_nested(key)
    r = Marshal.load(Marshal.dump(self))
    r.except_nested!(key)
  end

  def except_nested!(key)
    self.reject!{|k, _| k == key || k.to_s == key }
    self.each do |_, v|
      v.except_nested!(key) if v.is_a?(Hash)
      v.map!{|obj| obj.except_nested!(key) if obj.is_a?(Hash)} if v.is_a?(Array)
    end
  end
end
