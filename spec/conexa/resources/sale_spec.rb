# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Conexa::Sale do
  describe 'class methods' do
    describe '.url' do
      it 'returns sales endpoint' do
        expect(described_class.url).to eq('/sales')
      end
    end

    describe '.show_url' do
      it 'returns sale endpoint with id' do
        expect(described_class.show_url(1234)).to eq('/sale/1234')
      end
    end
  end

  describe 'instance methods' do
    let(:sale) do
      described_class.new(
        'saleId' => 1234,
        'status' => 'notBilled',
        'customerId' => 450,
        'requesterId' => nil,
        'productId' => 2521,
        'sellerId' => 10,
        'quantity' => 2,
        'amount' => 159.98,
        'originalAmount' => 199.98,
        'discountValue' => 40.00,
        'referenceDate' => '2024-01-15',
        'notes' => 'Test sale',
        'createdAt' => '2024-01-15T10:00:00Z',
        'updatedAt' => '2024-01-15T10:30:00Z'
      )
    end

    describe '#id / #saleId' do
      it 'returns sale ID' do
        expect(sale.id).to eq(1234)
        expect(sale.saleId).to eq(1234)
      end
    end

    describe '#status' do
      it 'returns status' do
        expect(sale.status).to eq('notBilled')
      end
    end

    describe '#customerId' do
      it 'returns customer ID' do
        expect(sale.customerId).to eq(450)
      end
    end

    describe '#productId' do
      it 'returns product ID' do
        expect(sale.productId).to eq(2521)
      end
    end

    describe '#quantity' do
      it 'returns quantity' do
        expect(sale.quantity).to eq(2)
      end
    end

    describe '#amount' do
      it 'returns final amount' do
        expect(sale.amount).to eq(159.98)
      end
    end

    describe '#originalAmount' do
      it 'returns original amount before discount' do
        expect(sale.originalAmount).to eq(199.98)
      end
    end

    describe '#discountValue' do
      it 'returns discount value' do
        expect(sale.discountValue).to eq(40.00)
      end
    end

    describe '#referenceDate' do
      it 'returns reference date' do
        expect(sale.referenceDate).to eq('2024-01-15')
      end
    end

    describe '#notes' do
      it 'returns notes' do
        expect(sale.notes).to eq('Test sale')
      end
    end

    describe 'status helpers' do
      context 'when notBilled' do
        it '#editable? returns true' do
          expect(sale.editable?).to be true
        end

        it '#billed? returns false' do
          expect(sale.billed?).to be false
        end

        it '#paid? returns false' do
          expect(sale.paid?).to be false
        end
      end

      context 'when billed' do
        let(:billed_sale) { described_class.new('status' => 'billed') }

        it '#billed? returns true' do
          expect(billed_sale.billed?).to be true
        end

        it '#editable? returns false' do
          expect(billed_sale.editable?).to be false
        end
      end

      context 'when paid' do
        let(:paid_sale) { described_class.new('status' => 'paid') }

        it '#paid? returns true' do
          expect(paid_sale.paid?).to be true
        end

        it '#editable? returns false' do
          expect(paid_sale.editable?).to be false
        end
      end
    end
  end
end
