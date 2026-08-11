# frozen_string_literal: true

module Conexa
  # Contract resource for recurring billing contracts
  #
  # == Creating a contract
  #
  # Required: +plan_id+, +customer_id+, +payment_frequency+ (+monthly+,
  # +bimonthly+, +quarterly+, +semester+ or +yearly+) and +start_date+.
  #
  #   Conexa::Contract.create(
  #     plan_id: 5, customer_id: 127,
  #     payment_frequency: 'monthly', start_date: '2026-01-01'
  #   )
  #
  # === +due_day+ is conditionally required *and* conditionally forbidden
  #
  # Required on a customer's **first** contract (or when they use automatic
  # invoicing); **rejected** on every later one, which inherits the customer's
  # +defaultDueDay+:
  #
  #   422 CONTRACT_RECURRING_SALE_10
  #   "The due day can not be informed for customers who already have a contract"
  #
  # Code that always sends +due_day+ works at onboarding and fails forever after.
  # Read the code off the exception rather than the message:
  #
  #   rescue Conexa::ResponseError => e
  #     retry_without_due_day if e.api_error_codes.include?('CONTRACT_RECURRING_SALE_10')
  #   end
  #
  # === Creating, charging and settling in one call
  #
  # +generate_sales: 'firstOccurrenceSettleRetroactive'+ also generates *and
  # settles* retroactive charges, and then requires +expense_settlement+. It
  # replaces a three-call sequence in which each step can fail on its own.
  #
  #   Conexa::Contract.create(
  #     plan_id: 5, customer_id: 127,
  #     payment_frequency: 'monthly', start_date: '2026-01-01',
  #     generate_sales: 'firstOccurrenceSettleRetroactive',
  #     expense_settlement: { receiving_method_id: 53, account_id: 1 }
  #   )
  #
  # Other documented values: +firstOccurrence+ (default), +currentOccurrence+,
  # +nextOccurrence+.
  #
  # === Other documented fields
  #
  # +end_date+, +first_due_date+ (required when the customer uses automatic
  # invoicing), +fidelity_date+, +amount+, +discount_value+, +seller_id+,
  # +contract_summary+, +notes+, +membership_fee+, +nfse_description+,
  # +prorata_type+ (+startOfMonth+ / +notCalculate+ / +perDueDate+), +refund+
  # (an explicit +nil+ opts out even when the plan configures one),
  # +complementary_services+ (array), +extra_fields+ (array).
  #
  # +cost_center_id+ is *not* accepted on create — it 400s — even though it is
  # present when the contract is read back.
  #
  # @example End a contract
  #   Conexa::Contract.set_end_date(456, date: '2026-12-31')
  #
  # @!attribute [r] contract_id
  #   @return [Integer] Contract ID (also accessible as #id)
  # @!attribute [r] customer_id
  #   @return [Integer] Customer ID
  # @!attribute [r] plan_id
  #   @return [Integer, nil] Plan ID
  # @!attribute [r] status
  #   @return [String] Status: active, ended, cancelled
  # @!attribute [r] start_date
  #   @return [String] Start date
  # @!attribute [r] end_date
  #   @return [String, nil] End date
  # @!attribute [r] payment_day
  #   @return [Integer] Payment day (1-28)
  # @!attribute [r] value
  #   @return [Float] Contract value
  # @!attribute [r] billing_day
  #   @return [Integer] Billing day
  #
  class Contract < Model
    primary_key_attribute :contract_id

    # Check if contract is active
    # @return [Boolean]
    def active?
      status == 'active'
    end

    # Check if contract is cancelled/ended
    # @return [Boolean]
    def ended?
      status == 'ended' || status == 'cancelled'
    end

    # Set this contract's end date — closing it, or amending an existing closure.
    #
    # The endpoint is documented as "encerra um contrato ativo **ou atualiza a
    # data de encerramento**": it both closes and amends, and a future date on an
    # already-closed contract **reopens** it. `end_contract` is kept as an alias,
    # but the name understates what the call does.
    #
    # A contract cannot be closed retroactively past a day that already has
    # invoiced sales (422 CONTRACT_RECURRING_SALE_23).
    #
    # The API may answer with an empty body on success.
    #
    # @param params [Hash]
    # @option params [String] :date required, yyyy-MM-dd — the closing date
    # @option params [Integer] :reason_id closing-reason id, from
    #   Listagem de Contratos > Outros Cadastros > Motivo de Encerramento de Contrato
    # @option params [Boolean] :unlink_customer unlinks DDRs, mailboxes, extensions
    #   and recurring sales. Requires date <= today and no other active contracts;
    #   ends *all* the customer's recurring sales and cancels their uninvoiced sales.
    # @option params [String] :end_date deprecated alias for +:date+
    # @return [self]
    def set_end_date(params = {})
      params = self.class.normalize_end_params(params)
      Conexa::Request.patch(self.class.show_url("end", primary_key), params: params).call(class_name)
      self
    end
    alias_method :end_contract, :set_end_date

    class << self
      # Set a contract's end date by ID
      # @see #set_end_date
      # @param id [Integer, String] contract ID
      # @return [Contract]
      def set_end_date(id, params = {})
        find(id).set_end_date(params)
      end
      alias_method :end_contract, :set_end_date

      # The documented field is `date`; the gem used to send `end_date`, which
      # camelizes to `endDate` and is rejected: "endDate field does not exist or
      # is not available in the company".
      # @api private
      def normalize_end_params(params)
        params = params.dup
        legacy = params.delete(:end_date) || params.delete("end_date")
        return params unless legacy

        warn "DEPRECATION WARNING: `end_date:` foi renomeado para `date:` em conexa 0.2.0 " \
             "(a API v2 rejeita `endDate`). O alias será removido em 0.3.0."
        params[:date] ||= legacy
        params
      end

      # Create contract with custom product items
      # @param params [Hash] contract params including :items array
      # @return [Contract]
      def create_with_products(params = {})
        create(params)
      end
    end
  end
end
