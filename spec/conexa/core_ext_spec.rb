# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Core Extensions' do
  describe '#blank?' do
    context 'with nil' do
      it 'returns true' do
        expect(nil.blank?).to be true
      end
    end

    context 'with false' do
      it 'returns true' do
        expect(false.blank?).to be true
      end
    end

    context 'with empty string' do
      it 'returns true' do
        expect(''.blank?).to be true
      end
    end

    context 'with empty array' do
      it 'returns true' do
        expect([].blank?).to be true
      end
    end

    context 'with empty hash' do
      it 'returns true' do
        expect({}.blank?).to be true
      end
    end

    context 'with non-empty string' do
      it 'returns false' do
        expect('hello'.blank?).to be false
      end
    end

    context 'with non-empty array' do
      it 'returns false' do
        expect([1, 2].blank?).to be false
      end
    end

    context 'with number' do
      it 'returns false' do
        expect(0.blank?).to be false
        expect(1.blank?).to be false
      end
    end

    context 'with true' do
      it 'returns false' do
        expect(true.blank?).to be false
      end
    end
  end

  describe '#present?' do
    it 'returns opposite of blank?' do
      expect(nil.present?).to be false
      expect(''.present?).to be false
      expect('hello'.present?).to be true
      expect([1].present?).to be true
    end
  end
end
