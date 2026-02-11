## 0.0.6
### Bug Fixes
- **camelize_hash nil guard** - Adiciona proteção contra `nil` no método `camelize_hash` para evitar `NoMethodError: undefined method 'each' for nil:NilClass` quando a API retorna resposta inesperada ([#6](https://github.com/guilhermegazzinelli/conexa-ruby/pull/6))
- **Result#empty? delegation** - Corrige `empty?` no `Result` para delegar para `data.empty?` ao invés de verificar `@attributes.empty?`. Isso corrige o caso onde resultados vazios retornavam `false` em `empty?` devido à presença de dados de paginação ([#7](https://github.com/guilhermegazzinelli/conexa-ruby/pull/7), closes [#5](https://github.com/guilhermegazzinelli/conexa-ruby/issues/5))

### Tests
- Adiciona testes para `camelize_hash` com input `nil`
- Adiciona spec completo para `Conexa::Result` (`spec/conexa/resources/result_spec.rb`)

## 0.0.5
- Adiciona novos recursos: `InvoicingMethod`, `CreditCard`, `Supplier`, `Company`
- Adiciona sub-processos em recursos existentes:
  - `Charge#settle` - Quitar cobrança
  - `Charge#pix` - Obter QR Code PIX
  - `Contract#end_contract` - Encerrar contrato
  - `RecurringSale#end_recurring_sale` - Encerrar venda recorrente
- Adiciona documentação de paginação, filtragem e navegação no README
- Adiciona README em português (README_pt-BR.md)
- Documenta delegação de métodos do Result para data (first, last, length, etc.)

## 0.0.4
- Adiciona paginação em elementos que retornam array e possuam pagination no objeto de resposta
- Adiciona delegação para métodos com blocos ao receber um Conexa::Result

## 0.0.1
- Início da Gem Conexa Ruby
