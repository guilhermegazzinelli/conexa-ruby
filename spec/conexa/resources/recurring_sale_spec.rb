# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Conexa::RecurringSale do
  describe 'class methods' do
    describe '.url' do
      it 'returns recurringSales endpoint' do
        expect(described_class.url).to eq('/recurringSales')
      end
    end

    describe '.show_url' do
      it 'returns recurringSale endpoint with id' do
        expect(described_class.show_url(555)).to eq('/recurringSale/555')
      end

      it 'supports action paths' do
        expect(described_class.show_url('end', 555)).to eq('/recurringSale/end/555')
      end
    end
  end
end
