# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Conexa::Company do
  describe 'class methods' do
    describe '.url' do
      it 'returns companies endpoint' do
        expect(described_class.url).to eq('/companys')
      end
    end

    describe '.show_url' do
      it 'returns company endpoint with id' do
        expect(described_class.show_url(3)).to eq('/company/3')
      end
    end
  end

  describe 'inheritance' do
    it 'inherits from Model' do
      expect(described_class).to be < Conexa::Model
    end
  end
end
