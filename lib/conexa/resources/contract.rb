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
  # == Attributes
  #
  # Checked against a live response, not only the collection — which omits
  # +isActive+, +extraFields+ and +firstDueDate+ from its `GET /contract/:id`
  # examples even though the API returns them.
  #
  # **There is no +status+ field on a contract.** +is_active+ is how you tell an
  # open contract from a closed one.
  #
  # @!attribute [r] contract_id
  #   @return [Integer] Contract ID (also accessible as #id)
  # @!attribute [r] customer_id
  #   @return [Integer] Customer ID
  # @!attribute [r] plan_id
  #   @return [Integer, nil] Plan ID
  # @!attribute [r] is_active
  #   @return [Boolean] whether the contract is open
  # @!attribute [r] start_date
  #   @return [String] Start date
  # @!attribute [r] end_date
  #   @return [String, nil] closing date. May be in the future on an **active**
  #     contract — a scheduled close is not a closed contract.
  # @!attribute [r] end_reason_id
  #   @return [Integer, nil] closing-reason id
  # @!attribute [r] due_day
  #   @return [Integer] day of the month the contract falls due
  # @!attribute [r] first_due_date
  #   @return [String, nil] due date of the first instalment
  # @!attribute [r] amount
  #   @return [Float] contract value
  # @!attribute [r] payment_frequency
  #   @return [String] monthly, bimonthly, quarterly, semester or yearly
  # @!attribute [r] date_sales_generation
  #   @return [String, nil] when sales are generated from the contract
  # @!attribute [r] cost_center_id
  #   @return [Integer, nil] cost centre — present on read, rejected on create
  # @!attribute [r] seller_id
  #   @return [Integer, nil] seller (user) id
  # @!attribute [r] contract_summary
  #   @return [String, nil] short description
  # @!attribute [r] fidelity_date
  #   @return [String, nil] loyalty date
  # @!attribute [r] had_prorata
  #   @return [Boolean] whether pro rata was applied
  #
  class Contract < Model
    primary_key_attribute :contract_id

    # Is this contract open?
    #
    # Reads +is_active+, which is what the API sends. It used to compare a
    # +status+ field that contracts have never had, so it answered +false+ for an
    # active contract — the answer that makes a caller create a second one.
    #
    # Deliberately not derived from +end_date+: an active contract can carry a
    # future closing date, so a present +end_date+ does not mean closed.
    #
    # **Prefer {#ended?} over `!active?`.** Ruby cannot tell +nil+ from +false+
    # through `!`, so `!active?` reads an *unknown* contract as closed — the
    # same "treat unknown as inactive" that this fix exists to remove. `ended?`
    # preserves the nil.
    #
    # @return [Boolean, nil] nil when the response did not carry +is_active+,
    #   rather than a guess
    def active?
      value = is_active
      value.nil? ? nil : !!value
    end

    # Is this contract closed?
    # @see #active?
    # @return [Boolean, nil] nil when the response did not carry +is_active+
    def ended?
      value = active?
      value.nil? ? nil : !value
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

      # @deprecated Use {Conexa::Util.normalize_end_date_param}, which both "end"
      #   endpoints share.
      # @api private
      def normalize_end_params(params)
        Util.normalize_end_date_param(params)
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
