# frozen_string_literal: true

module Conexa
  # Credit card, registered against the customer through Cielo.
  #
  # **Write-only.** API v2 exposes `POST /creditCard` and nothing else — the card
  # number and CVC live encrypted at Cielo, not in Conexa, so there is nothing to
  # read back. Verified against a live tenant on 2026-08-12:
  #
  #   GET /creditCard      => 404 "Unable to resolve the request"
  #   GET /creditCard/:id  => 404 "unable to find the requested action \"view\""
  #
  # Neither is the "does not exist or you have no permission to access it"
  # wording the API uses for a resource an account cannot see, and the collection
  # documents a 403 for authorization — so this is the shape of the API, not a
  # feature switched off for one tenant.
  #
  # `#save` and `#destroy` are left in place but are **undocumented and
  # unverified**: the collection describes only `POST`, and the documented
  # behaviour of `default:` and `enable_recurring:` — re-registering a card
  # changes which one is default, or turns recurrence off — reads as if there is
  # no update path at all. They were not probed, because probing them means
  # writing. Treat a 404 from either as expected rather than as a bug.
  #
  # @example Register a card
  #   Conexa::CreditCard.create(
  #     customer_id: 127, number: '4111111111111111',
  #     expiration_date: '12/26', cvc: '123', name: 'JOAO DA SILVA',
  #     default: true, enable_recurring: true
  #   )
  class CreditCard < Model
    primary_key_attribute :credit_card_id

    NO_READ = "a API v2 não expõe leitura de cartão de crédito: só " \
              "POST /creditCard é documentado, e GET /creditCard[/:id] responde 404. " \
              "Os dados do cartão ficam na Cielo, não no Conexa."

    # Model#create re-fetches the created record to pick up server-side defaults.
    # There is no read here, so the id from the response is all there is.
    # @return [self]
    def create
      created = Conexa::Request.post(self.class.show_url, params: to_hash).call(class_name)
      set_primary_key created.attributes['id'] if created.respond_to?(:attributes)
      self
    end

    class << self
      def url(*params)
        ["/creditCard", *params].join '/'
      end

      def show_url(*params)
        ["/creditCard", *params].join '/'
      end

      # Every read name Model provides, refused with an explanation rather than
      # left to return a bare Conexa::NotFound that reads as "no such card".
      %i[all where find find_by find_by_hash find_by_id].each do |name|
        define_method(name) { |*, **| raise RequestError, NO_READ }
      end
    end
  end
end
