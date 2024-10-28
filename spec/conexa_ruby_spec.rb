# frozen_string_literal: true

require 'spec_helper'
require_relative '../lib/conexa'

RSpec.describe Conexa do
   describe 'autoload de resources' do
    it 'carrega os arquivos de resources corretamente' do
      # Simular os arquivos carregados pelo Dir[]
      paths = Dir[File.expand_path('../../lib/conexa/resources/*.rb', __FILE__)]
      expect(paths).not_to be_empty

      paths.each do |path|
        expect { require path }.not_to raise_error
      end
    end
  end

  describe 'error handling' do
    it 'herda de StandardError' do
      expect(Conexa::Error).to be < StandardError
    end
  end
end