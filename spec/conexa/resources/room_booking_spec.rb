# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Conexa::RoomBooking do
  describe 'inheritance' do
    it 'inherits from Model' do
      expect(described_class).to be < Conexa::Model
    end
  end

  describe 'class methods' do
    describe '.url' do
      it 'returns room/bookings endpoint' do
        expect(described_class.url).to eq('/room/bookings')
      end
    end

    describe '.show_url' do
      it 'returns room/booking endpoint with id' do
        expect(described_class.show_url(143063)).to eq('/room/booking/143063')
      end

      it 'supports action paths' do
        expect(described_class.show_url(143063, 'cancel')).to eq('/room/booking/143063/cancel')
        expect(described_class.show_url(143063, 'checkout')).to eq('/room/booking/143063/checkout')
      end
    end
  end

  describe 'instance methods' do
    let(:booking) { described_class.new('bookingId' => 143063, 'status' => 'confirmed') }

    it 'has correct id' do
      expect(booking.id).to eq(143063)
    end

    it 'responds to cancel' do
      expect(booking).to respond_to(:cancel)
    end

    it 'responds to checkout' do
      expect(booking).to respond_to(:checkout)
    end
  end
end
