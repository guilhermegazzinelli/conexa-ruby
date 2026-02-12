# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Conexa::Contract do
  describe 'class methods' do
    describe '.url' do
      it 'returns contracts endpoint' do
        expect(described_class.url).to eq('/contracts')
      end
    end

    describe '.show_url' do
      it 'returns contract endpoint with id' do
        expect(described_class.show_url(456)).to eq('/contract/456')
      end

      it 'supports action paths' do
        expect(described_class.show_url('end', 456)).to eq('/contract/end/456')
      end
    end
  end

  describe 'instance methods' do
    let(:contract) do
      described_class.new(
        'contractId' => 456,
        'status' => 'active',
        'customerId' => 127,
        'planId' => 5,
        'startDate' => '2024-01-01',
        'endDate' => nil,
        'paymentDay' => 10
      )
    end

    describe '#id / #contractId' do
      it 'returns contract ID' do
        expect(contract.id).to eq(456)
        expect(contract.contractId).to eq(456)
      end
    end

    describe '#status' do
      it 'returns status' do
        expect(contract.status).to eq('active')
      end
    end

    describe '#customerId' do
      it 'returns customer ID' do
        expect(contract.customerId).to eq(127)
      end
    end

    describe '#planId' do
      it 'returns plan ID' do
        expect(contract.planId).to eq(5)
      end
    end

    describe '#startDate' do
      it 'returns start date' do
        expect(contract.startDate).to eq('2024-01-01')
      end
    end

    describe '#endDate' do
      it 'returns end date (nil when active)' do
        expect(contract.endDate).to be_nil
      end
    end

    describe '#paymentDay' do
      it 'returns payment day' do
        expect(contract.paymentDay).to eq(10)
      end
    end

    describe 'status helpers' do
      context 'when active' do
        it '#active? returns true' do
          expect(contract.active?).to be true
        end

        it '#ended? returns false' do
          expect(contract.ended?).to be false
        end
      end

      context 'when ended' do
        let(:ended_contract) { described_class.new('status' => 'ended') }

        it '#ended? returns true' do
          expect(ended_contract.ended?).to be true
        end

        it '#active? returns false' do
          expect(ended_contract.active?).to be false
        end
      end

      context 'when cancelled' do
        let(:cancelled_contract) { described_class.new('status' => 'cancelled') }

        it '#ended? returns true' do
          expect(cancelled_contract.ended?).to be true
        end
      end
    end
  end
end
