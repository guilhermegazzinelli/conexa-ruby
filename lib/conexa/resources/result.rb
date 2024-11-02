module Conexa
  class Result  < ConexaObject

    def inspect
      self.data.inspect
    end

    def method_missing(name, *args, &block)
      name = Util.to_snake_case(name.to_s)

      if @attributes["data"].respond_to?(name) && args != ["data"]
        return @attributes["data"].public_send name, *args, &block
      end

      super name, *args, &block
    end

  end
end
