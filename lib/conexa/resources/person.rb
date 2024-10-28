module Conexa
  class Person < Model
    class << self
      def all(*args, **params)
        raise NoMethodError
      end

      def find_by_id(id, **options)
        raise NoMethodError
      end


      def find_by(params = Hash.new, page = nil, size = nil)
        raise NoMethodError
      end
    end
  end
end
