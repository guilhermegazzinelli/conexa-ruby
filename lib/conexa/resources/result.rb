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

    # @return [Boolean] always a boolean — it used to yield nil when there was no
    #   pagination at all, which is falsy but not `false`, and leaks out of any
    #   caller that serialises or compares the result.
    def has_next?
      pagination.respond_to?(:has_next) && pagination.has_next == true
    end

    def next_page
      raise StopIteration, "No more pages" unless has_next?
      raise Conexa::RequestError, "No query context available for next_page" unless @query_context

      limit  = pagination.limit
      offset = pagination.offset
      unless limit.is_a?(Integer) && offset.is_a?(Integer)
        raise Conexa::ResponseError.new(@query_context[:params], nil,
                                        "pagination is missing limit/offset " \
                                        "(limit=#{limit.inspect}, offset=#{offset.inspect}), " \
                                        "so the next page cannot be computed")
      end

      resource_class = @query_context[:resource_class]

      begin
        next_params = Marshal.load(Marshal.dump(@query_context[:params]))
      rescue TypeError
        # A non-marshallable filter (a Proc, an IO) in the original query.
        next_params = @query_context[:params].dup
      end

      next_params[:limit] = limit
      next_params[:offset] = offset + limit
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
