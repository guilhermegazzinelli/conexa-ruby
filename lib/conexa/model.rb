module Conexa
  class Model < ConexaObject
    def create
      set_primary_key Conexa::Request.post(self.class.show_url, params: to_hash).call(class_name).attributes['id']
      fetch
    end


    def save
      update Conexa::Request.patch(self.class.show_url(primary_key), params: unsaved_attributes).call(class_name)
      self
    end

    def fetch
      update self.class.find(primary_key)
      self
    end

    def primary_key
      id
    end

    def id
      send(primary_key_name) || attributes['id']
    end

    def set_primary_key id
      send(primary_key_name+"=", id)
    end

    def primary_key_name
      class_name.downcase + "_id"
    end

    def class_name
      self.class.to_s.split('::').last
    end

    def destroy
      raise RequestError.new('Invalid ID') unless id.present?
      update Conexa::Request.delete( self.class.show_url(primary_key) ).call(class_name)
    end

    class << self
      def create(*args)
        self.new(*args).create
      end

      def find_by_id(id, **options)
        raise RequestError.new('Invalid ID') unless id.present?
        Conexa::Request.get(show_url(id), params: options).call underscored_class_name
      end
      alias :find :find_by_id


      def find_by(params = Hash.new, page = nil, size = nil)
        params = extract_page_size_or_params(page, size, **params)
        raise RequestError.new('Invalid page size') if params[:page] < 1 or params[:size] < 1

        Conexa::Request.get(url, params: params).call underscored_class_name
      end
      alias :find_by_hash :find_by

      def all(*args, **params)
        params = extract_page_size_or_params(*args, **params)
        find_by params
      end
      alias :where :all

      def destroy id
        self.new(id: id).destroy
      end

      def url(*params)
        ["/#{ CGI.escape class_name }s", *params].join '/'
      end

      def show_url(*params)
        ["/#{ CGI.escape class_name }", *params].join '/'
      end

      def class_name
        self.name.split('::').last.downcase
      end

      def underscored_class_name
        self.name.split('::').last.gsub(/[a-z0-9][A-Z]/){|s| "#{s[0]}_#{s[1]}"}.downcase
      end

      def extract_page_size_or_params(*args, **params)
        params[:page]  ||= args[0] || 1
        params[:size] ||= args[1] || 100
        params
      end
    end
  end
end
