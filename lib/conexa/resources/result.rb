module Conexa
  class Result  < ConexaObject

    def inspect
      self.data.inspect
    end

    # Delegate empty? to data array instead of checking @attributes
    # This fixes the case where Conexa returns empty results but
    # @attributes still has pagination info, making empty? return false
    def empty?
      data.nil? || data.empty?
    end

    def pagination
      @attributes["pagination"]
    end

    def respond_to?(name, include_all = false)
      return true if name.to_s.end_with? '='

      @attributes.has_key?(name.to_s) ||      super
    end

    def method_missing(name, *args, &block)
      name = Util.to_snake_case(name.to_s)

      if @attributes["data"] && @attributes["data"].respond_to?(name) && args != ["data"]
        return @attributes["data"].public_send name, *args, &block
      end

      unless block_given?

        if name.end_with?('=') && args.size == 1
          attribute_name = name[0...-1]
          return self[attribute_name] = args[0]
        end

        if args.size == 0
          return self[name] || self[name.to_sym]
        end
      end

      if attributes.respond_to? name
        return attributes.public_send name, *args, &block
      end

      super name, *args, &block
    end

  end
end
