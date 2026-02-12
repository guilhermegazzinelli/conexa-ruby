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

  describe 'inheritance' do
    it 'inherits from Model' do
      expect(described_class).to be < Conexa::Model
    end
  end

  describe 'instance methods' do
    let(:charge) { described_class.new('chargeId' => 789) }

    it 'responds to settle' do
      expect(charge).to respond_to(:settle)
    end

    it 'responds to pix' do
      expect(charge).to respond_to(:pix)
    end
  end
end
