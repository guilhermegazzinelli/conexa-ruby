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
