# frozen_string_literal: true

module Conexa
  # Base class for all API resources (Customer, Charge, Contract, etc.)
  #
  # == Attribute Access
  #
  # Attributes are automatically accessible via method_missing:
  #   customer.name           # => "Empresa ABC"
  #   customer.company_id     # => 3
  #   customer.is_active      # => true
  #
  # The API returns camelCase (companyId), ConexaObject converts to snake_case
  # (company_id), and method_missing handles the lookup transparently.
  #
  # == Primary Key
  #
  # Each resource declares primary_key_attribute, which defines #id and the
  # operations that need the resource ID (destroy, save, fetch, etc.):
  #
  #   class Charge < Model
  #     primary_key_attribute :charge_id
  #   end
  #
  #   charge.charge_id  # => 123
  #   charge.chargeId   # => 123 (camelCase alias for backwards compat)
  #   charge.id         # => 123 — the resource's own key, falling back to a
  #                     #    plain "id" attribute, which is what write endpoints
  #                     #    return and what Model#create reads back
  #
  # == Why explicit primary_key_attribute?
  #
  # The default primary_key_name generates "classname_id" (e.g., "charge_id"),
  # but compound names like RecurringSale would generate "recurringsale_id"
  # instead of "recurring_sale_id". Explicit declaration ensures correctness.
  #
  class Model < ConexaObject
    extend Deprecatable

    def create
      created = Conexa::Request.post(self.class.show_url, params: to_hash).call(class_name)

      # A create that answers with no usable body leaves us nothing to identify
      # the new record by, so there is nothing to re-fetch. Returning the local
      # object is honest; raising NoMethodError from `nil.attributes` was not.
      return self unless created.respond_to?(:attributes)

      set_primary_key created.attributes['id']
      fetch
    end

    def save
      # #destroy has always guarded this; #save did not, so an object with no id
      # silently issued `PATCH /customer/` instead of failing fast.
      raise RequestError.new('Invalid ID') unless id.present?

      update Conexa::Request.patch(self.class.show_url(primary_key), params: unsaved_attributes).call(class_name)
      self
    end

    def fetch
      fetched = self.class.find(primary_key)

      # #update ignores anything with no attributes, which is right for a write
      # that answers with no body — but a *refresh* that comes back empty must
      # not quietly leave stale values in place reporting success.
      unless fetched.respond_to?(:attributes)
        raise ResponseError.new({ url: self.class.show_url(primary_key) }, nil,
                                "a API respondeu sem corpo: nada para atualizar")
      end

      update fetched
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
      Util.to_snake_case(class_name) + "_id"
    end

    def class_name
      self.class.to_s.split('::').last
    end

    def destroy
      raise RequestError.new('Invalid ID') unless id.present?
      update Conexa::Request.delete(self.class.show_url(primary_key)).call(class_name)
      self
    end

    class << self
      # DSL for the primary key attribute
      # @example
      #   primary_key_attribute :charge_id
      #   # Generates: charge_id + chargeId alias + #id (with an "id" fallback)
      def primary_key_attribute(snake_name)
        camel_name = Util.camelize_str(snake_name.to_s)

        define_method(snake_name) do
          @attributes[snake_name.to_s]
        end

        alias_method camel_name.to_sym, snake_name

        # Not an alias: #id has to keep Model#id's documented fallback to a plain
        # "id" attribute. Write endpoints answer with {"id": N} rather than the
        # resource's own key — Model#create depends on exactly that — so aliasing
        # #id straight to #charge_id silently made the fallback dead code.
        define_method(:id) do
          @attributes[snake_name.to_s] || @attributes["id"]
        end
      end

      def create(*args)
        self.new(*args).create
      end

      def find_by_id(id, **options)
        # Surrounding whitespace is a copy-paste artefact, not a different id —
        # strip it rather than failing. Anything still unusable in a URL is caught
        # by Request#full_api_url and raised as a RequestError.
        id = id.to_s.strip if id.is_a?(String)
        raise RequestError.new('Invalid ID') unless id.present?

        Conexa::Request.get(show_url(id), params: options).call underscored_class_name
      end
      alias :find :find_by_id

      def find_by(params = Hash.new, page = nil, size = nil)
        # extract_page_size_or_params always returns limit/offset now, and
        # validates them, so there is no page/size left here to guard.
        params = extract_page_size_or_params(page, size, **params)

        result = Conexa::Request.get(url, params: params).call(
          underscored_class_name,
          query_context: { resource_class: self, params: params }
        )

        # A listing always answers with a Result, as the READMEs promise. Without
        # this, an empty body yielded nil and a bare-array body yielded an Array,
        # so `.data` / `.pagination` / `.next_page` blew up far from the cause.
        return result if result.is_a?(Conexa::Result)

        Conexa::Result.new("data" => Array(result), "pagination" => nil)
      end
      alias :find_by_hash :find_by

      def all(*args, **params)
        find_by(params, *args)
      end
      alias :where :all

      def destroy id
        instance = self.new
        instance.set_primary_key(id)
        instance.destroy
      end

      def url(*params)
        ["/#{ CGI.escape class_name }s", *params].join '/'
      end

      def show_url(*params)
        ["/#{ CGI.escape class_name }", *params].join '/'
      end

      def class_name
        name = self.name.split('::').last
        name[0].downcase + name[1..]
      end

      def underscored_class_name
        self.name.split('::').last.gsub(/[a-z0-9][A-Z]/){|s| "#{s[0]}_#{s[1]}"}.downcase
      end

      def extract_page_size_or_params(*args, **params)
        if args[0].is_a?(Hash)
          params = args[0].merge(params)
          page_val = nil
        else
          page_val = args[0]
        end
        size_val = args[1]

        # Explicit new pagination (limit/offset)
        if params.key?(:limit)
          unless params[:limit].is_a?(Integer) && params[:limit].positive?
            raise RequestError, "limit must be a positive integer"
          end

          params[:offset] ||= size_val if size_val.is_a?(Integer)
          params[:offset] ||= 0

          unless params[:offset].is_a?(Integer) && params[:offset] >= 0
            raise RequestError, "offset must be a non-negative integer"
          end

          params.delete(:page)
          params.delete(:size)
          return params
        end

        # Legacy pagination (page/size) — deprecated, and broken upstream.
        #
        # The API validates `page` and then ignores it, always returning the
        # first page with offset 0 and hasNext true, so a loop over `page` never
        # terminates and silently re-yields the same batch. Converting to
        # limit/offset fixes existing callers instead of leaving them with
        # plausible wrong answers.
        if params.key?(:page) || params.key?(:size) || page_val.is_a?(Integer)
          page = params.delete(:page) || page_val || 1
          size = params.delete(:size) || size_val || 100

          unless page.is_a?(Integer) && page.positive?
            raise RequestError, "page must be a positive integer"
          end
          unless size.is_a?(Integer) && size.positive?
            raise RequestError, "size must be a positive integer"
          end

          deprecate(:page_size,
                    "page/size foi substituído por limit/offset e será removido em " \
                    "conexa 0.3.0. A API v2 valida `page` e depois o ignora, devolvendo " \
                    "sempre a primeira página; os valores são convertidos para " \
                    "limit=size, offset=(page-1)*size.")

          params[:limit]  = size
          params[:offset] = (page - 1) * size
          return params
        end

        # Default: new pagination
        params[:limit] = 100
        params[:offset] = 0
        params
      end
    end
  end
end
