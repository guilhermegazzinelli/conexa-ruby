module Conexa
  class RecurringSale  < Model
    def url(*params)
      ["/recurringSales", *params].join '/'
    end

    def show_url(*params)
      ["/recurringSale", *params].join '/'
    end

    def ends_at(date)
      update Conexa::Request.patch(show_url("/end", primary_key)).call(underscored_class_name)
      self
    end
  end
end
