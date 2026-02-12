# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Conexa::Person do
  describe 'class methods' do
    describe '.all' do
      it 'raises NoMethodError (not available)' do
        expect { described_class.all }.to raise_error(NoMethodError)
      end
    end

    describe '.find_by_id' do
      it 'raises NoMethodError (not available)' do
        expect { described_class.find_by_id(1) }.to raise_error(NoMethodError)
      end
    end

    describe '.find_by' do
      it 'raises NoMethodError (not available)' do
        expect { described_class.find_by({}) }.to raise_error(NoMethodError)
      end
    end
  end

  describe 'inheritance' do
    it 'inherits from Model' do
      expect(described_class).to be < Conexa::Model
    end
  end
end
