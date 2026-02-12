# frozen_string_literal: true

module Conexa
  # Charge resource for billing/invoices
  #
  # @example Retrieve a charge
  #   charge = Conexa::Charge.find(789)
  #   charge.status  # => "pending"
  #
  # @example List charges
  #   charges = Conexa::Charge.all(customer_id: [127], status: 'pending')
  #
  # @example Settle (pay) a charge
  #   Conexa::Charge.settle(789)
  #
  class Charge < Model
    # @return [Integer] Charge ID
    def charge_id
      @attributes['charge_id']
    end
    alias_method :chargeId, :charge_id
    alias_method :id, :charge_id

    # @return [String] Charge status
    def status
      @attributes['status']
    end

    # @return [Float] Charge amount
    def amount
      @attributes['amount']
    end

    # @return [String] Due date
    def due_date
      @attributes['due_date']
    end
    alias_method :dueDate, :due_date

    # @return [Integer] Customer ID
    def customer_id
      @attributes['customer_id']
    end
    alias_method :customerId, :customer_id

    # Check if charge is paid
    # @return [Boolean]
    def paid?
      status == 'paid'
    end

    # Check if charge is pending
    # @return [Boolean]
    def pending?
      status == 'pending'
    end

    # Check if charge is overdue
    # @return [Boolean]
    def overdue?
      status == 'overdue'
    end

    # Settle (pay) this charge
    # @param params [Hash] optional payment details
    # @return [self]
    def settle(params = {})
      Conexa::Request.post(self.class.show_url("settle", primary_key), params: params).call(class_name)
      self
    end

    # Get PIX QR Code for this charge
    # @return [ConexaObject] PIX data including QR code
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
