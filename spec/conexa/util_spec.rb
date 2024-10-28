require 'spec_helper'
require 'conexa/util'

RSpec.describe Conexa::Util do
  describe '.singularize' do
    it 'converte uma palavra no plural para o singular (padrão simples)' do
      expect(described_class.singularize('cars')).to eq('car')
    end

    it 'mantém palavras já no singular' do
      expect(described_class.singularize('car')).to eq('car')
    end

    it 'converte uma palavra complexa de plural para singular' do
      expect(described_class.singularize('analises')).to eq('analise')
    end

    it 'converte símbolos de plural para singular' do
      expect(described_class.singularize(:cars)).to eq(:car)
    end
  end

  describe '.to_sym' do
    it 'converte uma string para símbolo' do
      expect(described_class.to_sym('hello')).to eq(:hello)
    end

    it 'converte uma string com espaços e hífens para símbolo' do
      expect(described_class.to_sym('hello - world')).to eq(:hello_world)
    end
  end

  describe '.to_snake_case' do
    it 'converte uma string em camelCase para snake_case' do
      expect(described_class.to_snake_case('camelCase')).to eq('camel_case')
    end

    it 'converte uma string com várias palavras em camelCase para snake_case' do
      expect(described_class.to_snake_case('CamelCaseString')).to eq('camel_case_string')
    end

    it 'não altera strings que já estão no formato snake_case' do
      expect(described_class.to_snake_case('already_snake_case')).to eq('already_snake_case')
    end
  end

  describe '.camelize_hash' do
    it 'converte chaves de snake_case para camelCase em um hash simples' do
      input_hash = { first_name: 'John', last_name: 'Doe' }
      expected_output = { firstName: 'John', lastName: 'Doe' }

      result = described_class.camelize_hash(input_hash)

      expect(result).to eq(expected_output)
    end

    it 'converte chaves de snake_case para camelCase em um hash aninhado' do
      input_hash = { user_info: { first_name: 'John', last_name: 'Doe' } }
      expected_output = { userInfo: { firstName: 'John', lastName: 'Doe' } }

      result = described_class.camelize_hash(input_hash)

      expect(result).to eq(expected_output)
    end

    it 'mantém os valores de tipos não-hash inalterados' do
      input_hash = { name: 'John', age: 30, is_active: true }
      expected_output = { name: 'John', age: 30, isActive: true }

      result = described_class.camelize_hash(input_hash)

      expect(result).to eq(expected_output)
    end

    it 'funciona com um hash vazio' do
      input_hash = {}
      expected_output = {}

      result = described_class.camelize_hash(input_hash)

      expect(result).to eq(expected_output)
    end
  end

  describe '.camel_case_lower' do
    it 'converte strings de snake_case para camelCase' do
      expect(described_class.camel_case_lower('first_name')).to eq('firstName')
      expect(described_class.camel_case_lower('last_name')).to eq('lastName')
      expect(described_class.camel_case_lower('user_info')).to eq('userInfo')
    end

    it 'retorna a string original se não houver underscores' do
      expect(described_class.camel_case_lower('name')).to eq('name')
    end
  end
end