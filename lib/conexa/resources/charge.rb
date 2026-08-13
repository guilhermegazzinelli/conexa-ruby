# frozen_string_literal: true

module Conexa
  # Charge resource for billing/invoices
  #
  # @example Retrieve a charge
  #   charge = Conexa::Charge.find(789)
  #   charge.status  # => "pending"
  #
  # @example List charges
  #   charges = Conexa::Charge.all(customer_id: [127], status: 'pending', limit: 50)
  #
  # @example Settle (pay) a charge
  #   Conexa::Charge.settle(789)
  #
  # @!attribute [r] charge_id
  #   @return [Integer] Charge ID (also accessible as #id)
  # @!attribute [r] customer_id
  #   @return [Integer] Customer ID
  # @!attribute [r] status
  #   @return [String] Status: pending, paid, overdue, cancelled
  # @!attribute [r] amount
  #   @return [Float] Charge amount
  # @!attribute [r] due_date
  #   @return [String] Due date
  # @!attribute [r] paid_at
  #   @return [String, nil] Payment date
  #
  class Charge < Model
    primary_key_attribute :charge_id

    # The values `status` can take on a charge, per the collection's field table
    # for `GET /charge/:id`.
    #
    # **`excluded` is here but not in {FILTERABLE_STATUSES}.** The two lists are
    # not the same thing: a charge can hold a status you cannot query by. This
    # constant shipped with nine values in 0.2.1 because it was built from the
    # filter's rejection message rather than from the field table.
    STATUSES = %w[unpaid paid negotiated generatedByNegotiation cancelled
                  denied thirdPartyCompany protested juridical excluded].freeze

    # What `GET /charges?status=` accepts. The API names them in the 400 it
    # returns for an unrecognised value, so this list is the API's own:
    #
    #   status=zzz -> 400 "Status is not on the list (unpaid, negotiated,
    #                 generatedByNegotiation, cancelled, paid, denied,
    #                 thirdPartyCompany, protested, juridical)"
    #
    # `pending` and `overdue` are in neither list, which is why the predicates
    # built on them never matched.
    FILTERABLE_STATUSES = (STATUSES - %w[excluded]).freeze

    # @return [Boolean]
    def paid?
      status == 'paid'
    end

    # Is this charge still open?
    # @return [Boolean]
    def unpaid?
      status == 'unpaid'
    end

    # @return [Boolean]
    def cancelled?
      status == 'cancelled'
    end

    # @deprecated The API has no `pending` status; the open state is `unpaid`.
    #   This alias only exists so callers written against the old, never-matching
    #   predicate keep working while they migrate.
    # @return [Boolean]
    def pending?
      self.class.deprecate(:pending?,
                           "`Charge#pending?` foi renomeado para `unpaid?` em conexa 0.2.1 — " \
                           "a API v2 não tem status `pending`, o estado em aberto chama-se " \
                           "`unpaid`. O alias será removido em 0.3.0.")
      unpaid?
    end

    # @deprecated The API has no `overdue` status. An overdue charge is `unpaid`
    #   with a `due_date` in the past; compare the date yourself.
    # @return [Boolean] always false
    def overdue?
      self.class.deprecate(:overdue?,
                           "`Charge#overdue?` sempre devolveu false — a API v2 não tem status " \
                           "`overdue`. Use `unpaid?` e compare `due_date`. O método será " \
                           "removido em 0.3.0.")
      false
    end

    # Settle (pay) this charge
    #
    # Moves money and, on a configured tenant, issues an NF-e. Not safe to retry
    # blindly: a second attempt on a settled charge answers 422 CHARGE_11.
    #
    # The API answers 204 with an empty body on success.
    #
    # @param params [Hash] settlement details
    # @option params [String] :settlement_date required, yyyy-MM-dd
    # @option params [Hash] :receiving_method required, {id:, installments_quantity:}
    # @option params [Integer] :account_id required
    # @option params [Float] :paid_amount defaults to the charge amount, without interest
    # @option params [Boolean] :send_email defaults to false
    # @return [self]
    def settle(params = {})
      Conexa::Request.patch(self.class.show_url("settle", primary_key), params: params).call(class_name)
      self
    end

    # Get PIX QR Code for this charge
    # @return [ConexaObject] PIX data including qr_code and qr_code_base64
    def pix
      Conexa::Request.get(self.class.show_url("pix", primary_key)).call("pix")
    end

    # Cancel this charge
    # @return [self]
    def cancel
      Conexa::Request.post(self.class.show_url("cancel", primary_key)).call(class_name)
      self
    end

    # Send charge notification by email
    # @return [self]
    def send_email
      Conexa::Request.post(self.class.show_url("sendEmail", primary_key)).call(class_name)
      self
    end

    class << self
      # Settle a charge by ID
      # @param id [Integer, String] charge ID
      # @param params [Hash] optional payment details
      # @return [Charge]
      def settle(id, params = {})
        find(id).settle(params)
      end

      # Cancel a charge by ID
      # @param id [Integer, String] charge ID
      # @return [Charge]
      def cancel(id)
        find(id).cancel
      end

      # Send email for a charge by ID
      # @param id [Integer, String] charge ID
      # @return [Charge]
      def send_email(id)
        find(id).send_email
      end

      # Get PIX for a charge by ID
      # @param id [Integer, String] charge ID
      # @return [ConexaObject]
      def pix(id)
        find(id).pix
      end
    end
  end
end
