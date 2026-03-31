# frozen_string_literal: true

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

    def has_next?
      pagination && pagination.has_next == true
    end

    def next_page
      raise StopIteration, "No more pages" unless has_next?
      raise "No query context available for next_page" unless @query_context

      resource_class = @query_context[:resource_class]
      next_params = Marshal.load(Marshal.dump(@query_context[:params]))

      next_params[:limit] = pagination.limit
      next_params[:offset] = pagination.offset + pagination.limit
      next_params.delete(:page)
      next_params.delete(:size)

      resource_class.find_by(next_params)
    end

    def respond_to_missing?(name, include_private = false)
      name_str = Util.to_snake_case(name.to_s)
      return true if name_str.end_with?('=')
      return true if @attributes["data"]&.respond_to?(name_str)

      @attributes.key?(name_str) || @attributes.key?(name_str.to_sym) || super
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
          if @attributes.key?(name)
            return @attributes[name]
          elsif @attributes.key?(name.to_sym)
            return @attributes[name.to_sym]
          end
          return nil
        end
      end

      if attributes.respond_to? name
        return attributes.public_send name, *args, &block
      end

      super name, *args, &block
    end

  end
end
