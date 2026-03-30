# frozen_string_literal: true

module Conexa
  # RoomBooking resource (Reserva de Sala)
  #
  # @example Create a room booking
  #   booking = Conexa::RoomBooking.create(
  #     room_id: 5,
  #     customer_id: 127,
  #     start_date: '2026-04-01T10:00:00-03:00',
  #     end_date: '2026-04-01T12:00:00-03:00'
  #   )
  #
  # @example Find a room booking
  #   booking = Conexa::RoomBooking.find(143063)
  #
  # @example List room bookings
  #   bookings = Conexa::RoomBooking.all(limit: 50)
  #
  # @example Cancel a booking
  #   Conexa::RoomBooking.cancel(143063)
  #
  # @!attribute [r] booking_id
  #   @return [Integer] Booking ID (also accessible as #id)
  # @!attribute [r] room_id
  #   @return [Integer] Room ID
  # @!attribute [r] customer_id
  #   @return [Integer] Customer ID
  # @!attribute [r] status
  #   @return [String] Booking status
  #
  class RoomBooking < Model
    primary_key_attribute :booking_id

    # Cancel this booking
    # @return [self]
    def cancel
      Conexa::Request.patch(self.class.show_url(primary_key, "cancel")).call(class_name)
      self
    end

    # Checkout this booking
    # @return [self]
    def checkout
      Conexa::Request.post(self.class.show_url(primary_key, "checkout")).call(class_name)
      self
    end

    class << self
      def url(*params)
        ["/room/bookings", *params].join '/'
      end

      def show_url(*params)
        ["/room/booking", *params].join '/'
      end

      # Cancel a booking by ID
      # @param id [Integer, String] booking ID
      # @return [RoomBooking]
      def cancel(id)
        find(id).cancel
      end

      # Checkout a booking by ID
      # @param id [Integer, String] booking ID
      # @return [RoomBooking]
      def checkout(id)
        find(id).checkout
      end

      # Perform a checkin
      # @param params [Hash] checkin parameters
      # @return [ConexaObject]
      def checkin(params = {})
        Conexa::Request.post("/checkin", params: params).call("room_booking")
      end

      # Perform a checkout (standalone)
      # @param params [Hash] checkout parameters
      # @return [ConexaObject]
      def standalone_checkout(params = {})
        Conexa::Request.post("/checkout", params: params).call("room_booking")
      end
    end
  end
end
