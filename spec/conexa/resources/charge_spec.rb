# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Conexa::Charge do
  describe 'class methods' do
    describe '.url' do
      it 'returns charges endpoint' do
        expect(described_class.url).to eq('/charges')
      end
    end

    describe '.show_url' do
      it 'returns charge endpoint with id' do
        expect(described_class.show_url(789)).to eq('/charge/789')
      end

      it 'returns charge endpoint with action' do
        expect(described_class.show_url('settle', 789)).to eq('/charge/settle/789')
      end
    end
  end

  describe 'instance methods' do
    let(:charge) do
      described_class.new(
        'chargeId' => 789,
        'status' => 'pending',
        'amount' => 199.90,
        'dueDate' => '2024-02-10',
        'customerId' => 127
      )
    end

    describe '#id / #chargeId' do
      it 'returns charge ID' do
        expect(charge.id).to eq(789)
        expect(charge.chargeId).to eq(789)
      end
    end

    describe '#status' do
      it 'returns status' do
        expect(charge.status).to eq('pending')
      end
    end

    describe '#amount' do
      it 'returns amount' do
        expect(charge.amount).to eq(199.90)
      end
    end

    describe '#dueDate' do
      it 'returns due date' do
        expect(charge.dueDate).to eq('2024-02-10')
      end
    end

    describe '#customerId' do
      it 'returns customer ID' do
        expect(charge.customerId).to eq(127)
      end
    end

    describe 'status helpers' do
      context 'when pending' do
        it '#pending? returns true' do
          expect(charge.pending?).to be true
        end

        it '#paid? returns false' do
          expect(charge.paid?).to be false
        end

        it '#overdue? returns false' do
          expect(charge.overdue?).to be false
        end
      end

      context 'when paid' do
        let(:paid_charge) { described_class.new('status' => 'paid') }

        it '#paid? returns true' do
          expect(paid_charge.paid?).to be true
        end

        it '#pending? returns false' do
          expect(paid_charge.pending?).to be false
        end
      end

      context 'when overdue' do
        let(:overdue_charge) { described_class.new('status' => 'overdue') }

        it '#overdue? returns true' do
          expect(overdue_charge.overdue?).to be true
        end
      end
    end
  end
end
