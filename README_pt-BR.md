# Conexa Ruby Gem

Biblioteca Ruby para integração com a API Conexa

**[English version](README.md)**

## Documentação

- [Site Conexa](https://conexa.app/)
- [Documentação da API](https://conexa.app/api-docs)
- [Coleção Postman da API Conexa](https://web.postman.co/workspace/8e1887b1-bef9-4e36-848f-2b6774a81022/collection/33452984-58f4d7ab-d280-4aac-8578-8366988ff7af)

## Primeiros Passos

### Instalação

```shell
gem install conexa-ruby
```

Ou adicione a seguinte linha ao seu `Gemfile`:

```ruby
gem 'conexa-ruby'
```

Depois execute `bundle install` no terminal.

### Configurar sua Chave de API

Você pode definir suas credenciais de API em Ruby:

```ruby
Conexa.configure do |config|
  config.api_token = ENV['API_TOKEN']
  config.api_host  = ENV['API_HOST']
end
```

Certifique-se de que as variáveis de ambiente `API_TOKEN` e `API_HOST` estejam configuradas com seu token e URL da API Conexa.

## Uso

Após a configuração, você pode começar a usar a gem para interagir com os recursos da API Conexa.

### Recursos Disponíveis

- `Bill` (Faturas)
- `Charge` (Cobranças)
- `Company` (Empresas)
- `Contract` (Contratos)
- `CreditCard` (Cartão de Crédito)
- `Customer` (Clientes)
- `InvoicingMethod` (Meios de Faturamento)
- `LegalPerson` (Pessoa Jurídica)
- `Person` (Pessoa)
- `Plan` (Planos)
- `Product` (Produtos)
- `RecurringSale` (Vendas Recorrentes)
- `Sale` (Vendas)
- `Supplier` (Fornecedores)

### Padrões de Métodos

Cada recurso segue um conjunto consistente de padrões de métodos:

- `Conexa::<NomeRecurso>.new(params).create` - Criar um novo recurso.
- `Conexa::<NomeRecurso>.all(params)` - Buscar todas as entidades com os parâmetros.
- `Conexa::<NomeRecurso>.find(id)` - Recuperar um recurso por ID.
- `Conexa::<NomeRecurso>.find(hash_filtros, page, size)` - Recuperar recursos com filtros e paginação.
- `Conexa::<NomeRecurso>.destroy(id)` - Excluir um recurso por ID.
- `Conexa::<NomeRecurso>.find(id).destroy` - Buscar e excluir um recurso.

### Paginação

A API utiliza os parâmetros `page` e `size` para paginação com os seguintes valores padrão:

- **page**: Número da página atual (padrão: `1`)
- **size**: Quantidade de itens por página (padrão: `100`)

#### Chamando com Paginação

```ruby
# Paginação padrão (página 1, 100 itens)
Conexa::Customer.all

# Argumentos posicionais (página, tamanho)
Conexa::Customer.all(2, 50)  # página 2, 50 itens por página

# Parâmetros nomeados
Conexa::Customer.all(page: 3, size: 25)

# Usando o alias `where`
Conexa::Customer.where(page: 2, size: 10)
```

### Objeto Result

Ao listar recursos, a API retorna um objeto `Conexa::Result` contendo:

- **data**: Array com os objetos do recurso
- **pagination**: Objeto `Conexa::Pagination` com metadados da paginação

```ruby
result = Conexa::Customer.all

# Acessar o array de dados
result.data        # => Array de objetos Conexa::Customer

# Acessar informações de paginação
result.pagination  # => Objeto Conexa::Pagination
```

#### Delegação de Métodos para Data

O objeto `Result` delega automaticamente métodos de Array para o atributo `data`. Isso significa que você pode chamar métodos como `first`, `second`, `last`, `length`, `count`, `each`, `map`, etc. diretamente no resultado:

```ruby
result = Conexa::Customer.all

# Estes métodos são delegados para result.data
result.first       # => Primeiro Conexa::Customer (equivale a result.data.first)
result.second      # => Segundo Conexa::Customer
result.last        # => Último Conexa::Customer
result.length      # => Quantidade de itens na página atual
result.count       # => Quantidade de itens na página atual
result.empty?      # => true se não houver resultados

# Iteração direta
result.each { |customer| puts customer.name }

# Transformações
result.map(&:name)     # => Array com os nomes dos clientes
result.select { |c| c.active }  # => Filtra clientes ativos
```

### Filtragem

Você pode filtrar resultados passando parâmetros junto com a paginação. Os filtros disponíveis variam por recurso.

#### Padrões Comuns de Filtro

```ruby
# Filtrar por nome
Conexa::Customer.all(name: "João", page: 1, size: 10)

# Filtrar por múltiplos IDs (sintaxe de array)
Conexa::Customer.all("id[]": [102, 103])

# Filtrar por empresa
Conexa::Customer.all("companyId[]": [3])
Conexa::Contract.all("companyId[]": [540], page: 2, size: 5)

# Múltiplos filtros combinados
Conexa::Company.all(
  "id[]": [3, 4],
  trade_name: "Acme",
  legal_name: "Acme Ltda",
  cnpj: "17.992.846/0001-58",
  city: "São Paulo",
  active: 1,
  page: 1,
  size: 5
)

# Filtrar faturas por status
Conexa::Bill.all(status: "pending", page: 1, size: 20)

# Filtrar vendas
Conexa::Sale.all(page: 2, size: 6)
```

#### Filtros Específicos por Recurso

| Recurso | Filtros Comuns |
|---------|---------------|
| Customer | `name`, `id[]`, `companyId[]` |
| Company | `id[]`, `tradeName`, `legalName`, `cnpj`, `city`, `active` |
| Contract | `companyId[]`, `active` |
| Bill | `status`, `companyId[]` |
| Plan | `id[]` |
| Sale | `date` |
| InvoicingMethod | `id[]`, `companyId[]`, `isActive`, `type` |

### Operações Específicas de Recursos (Sub-processos)

Alguns recursos possuem operações adicionais além do CRUD básico:

#### Operações de Cobrança (Charge)

```ruby
# Quitar uma cobrança
cobranca = Conexa::Charge.find(charge_id)
cobranca.settle(parametros_pagamento)

# Ou diretamente pelo ID
Conexa::Charge.settle(charge_id, parametros_pagamento)

# Obter QR Code PIX de uma cobrança
dados_pix = Conexa::Charge.pix(charge_id)
# Retorna dados do QR code para pagamento
```

#### Operações de Contrato (Contract)

```ruby
# Encerrar um contrato
contrato = Conexa::Contract.find(contract_id)
contrato.end_contract(end_date: "2024-12-31", reason: "Solicitação do cliente")

# Ou diretamente pelo ID
Conexa::Contract.end_contract(contract_id, end_date: "2024-12-31")
```

#### Operações de Venda Recorrente (RecurringSale)

```ruby
# Encerrar uma venda recorrente
venda_recorrente = Conexa::RecurringSale.find(recurring_sale_id)
venda_recorrente.end_recurring_sale(end_date: "2024-12-31")

# Ou diretamente pelo ID
Conexa::RecurringSale.end_recurring_sale(recurring_sale_id, end_date: "2024-12-31")
```

#### Meio de Faturamento (InvoicingMethod)

```ruby
# Listar meios de faturamento com filtros
Conexa::InvoicingMethod.all("companyId[]": [3], is_active: 1, type: "billet")

# Buscar por ID
Conexa::InvoicingMethod.find(invoicing_method_id)
```

#### Cartão de Crédito (CreditCard)

```ruby
# Cadastrar cartão de crédito para um cliente
Conexa::CreditCard.new(
  customer_id: customer_id,
  card_number: "4111111111111111",
  card_holder_name: "João Silva",
  expiration_date: "12/25",
  cvv: "123"
).create
```

#### Fornecedor (Supplier)

```ruby
# Criar fornecedor (pessoa jurídica)
Conexa::Supplier.new(
  company_id: company_id,
  legal_name: "Fornecedor Ltda",
  trade_name: "Fornecedor",
  cnpj: "12.345.678/0001-90"
).create

# Criar fornecedor (pessoa física)
Conexa::Supplier.new(
  company_id: company_id,
  name: "João Fornecedor",
  cpf: "123.456.789-00"
).create
```

### Navegando Entre Páginas

```ruby
# Buscar primeira página
pagina1 = Conexa::Customer.all(page: 1, size: 10)
puts "Página 1: #{pagina1.length} clientes"

# Buscar próxima página
pagina2 = Conexa::Customer.all(page: 2, size: 10)
puts "Página 2: #{pagina2.length} clientes"

# Verificar metadados de paginação
paginacao = pagina1.pagination
# paginacao contém total de registros, total de páginas, etc.
```

#### Iterando Por Todas as Páginas

```ruby
pagina = 1
tamanho = 100

loop do
  resultado = Conexa::Customer.all(page: pagina, size: tamanho)

  break if resultado.empty?

  resultado.each do |cliente|
    # Processar cada cliente
    puts cliente.name
  end

  pagina += 1
end
```

### Exemplos

#### Clientes (Customers)

##### Criando um Cliente

```ruby
cliente = Conexa::Customer.new(
  name:  'João Silva',
  email: 'joao.silva@exemplo.com',
  phone: '11-99999-1234'
).create
```

##### Recuperando um Cliente

```ruby
cliente = Conexa::Customer.find(customer_id)
```

##### Atualizando um Cliente

```ruby
cliente = Conexa::Customer.find(customer_id)
cliente.email = 'novo.email@exemplo.com'
cliente.save
```

##### Excluindo um Cliente

```ruby
Conexa::Customer.destroy(customer_id)
```

Ou:

```ruby
cliente = Conexa::Customer.find(customer_id)
cliente.destroy
```

##### Listando Clientes

```ruby
clientes = Conexa::Customer.find({ name: 'João Silva' }, 1, 20)
```

#### Faturas (Bills)

##### Criando uma Fatura

```ruby
fatura = Conexa::Bill.new(
  customer_id: customer_id,
  amount:      1000,    # em centavos
  due_date:    '2024-12-31'
).create
```

##### Recuperando uma Fatura

```ruby
fatura = Conexa::Bill.find(bill_id)
```

##### Excluindo uma Fatura

```ruby
Conexa::Bill.destroy(bill_id)
```

##### Listando Faturas

```ruby
faturas = Conexa::Bill.find({ status: 'pending' }, 1, 20)
```

#### Cobranças (Charges)

##### Criando uma Cobrança

```ruby
cobranca = Conexa::Charge.new(
  customer_id:          customer_id,
  amount:               1000,    # em centavos
  payment_method:       'credit_card',
  card_number:          '4111111111111111',
  card_holder_name:     'João Silva',
  card_expiration_date: '12/25',
  card_cvv:             '123'
).create
```

##### Recuperando uma Cobrança

```ruby
cobranca = Conexa::Charge.find(charge_id)
```

##### Excluindo uma Cobrança

```ruby
Conexa::Charge.destroy(charge_id)
```

##### Listando Cobranças

```ruby
cobrancas = Conexa::Charge.find({ status: 'paid' }, 1, 20)
```

#### Planos (Plans)

##### Criando um Plano

```ruby
plano = Conexa::Plan.new(
  name:          'Plano Premium',
  amount:        4990,   # em centavos
  billing_cycle: 'monthly'
).create
```

##### Recuperando um Plano

```ruby
plano = Conexa::Plan.find(plan_id)
```

##### Excluindo um Plano

```ruby
Conexa::Plan.destroy(plan_id)
```

##### Listando Planos

```ruby
planos = Conexa::Plan.find({}, 1, 20)
```

#### Contratos (Contracts)

##### Criando um Contrato

```ruby
contrato = Conexa::Contract.new(
  customer_id: customer_id,
  plan_id:     plan_id,
  start_date:  '2024-01-01',
  end_date:    '2024-12-31'
).create
```

##### Recuperando um Contrato

```ruby
contrato = Conexa::Contract.find(contract_id)
```

##### Excluindo um Contrato

```ruby
Conexa::Contract.destroy(contract_id)
```

##### Listando Contratos

```ruby
contratos = Conexa::Contract.find({ active: true }, 1, 20)
```

#### Produtos (Products)

##### Criando um Produto

```ruby
produto = Conexa::Product.new(
  name:        'Nome do Produto',
  description: 'Descrição do Produto',
  price:       2990  # em centavos
).create
```

##### Recuperando um Produto

```ruby
produto = Conexa::Product.find(product_id)
```

##### Excluindo um Produto

```ruby
Conexa::Product.destroy(product_id)
```

##### Listando Produtos

```ruby
produtos = Conexa::Product.find({ category: 'Eletrônicos' }, 1, 20)
```

#### Vendas (Sales)

##### Criando uma Venda

```ruby
venda = Conexa::Sale.new(
  customer_id:  customer_id,
  product_id:   product_id,
  quantity:     2,
  total_amount: 5980  # em centavos
).create
```

##### Recuperando uma Venda

```ruby
venda = Conexa::Sale.find(sale_id)
```

##### Excluindo uma Venda

```ruby
Conexa::Sale.destroy(sale_id)
```

##### Listando Vendas

```ruby
vendas = Conexa::Sale.find({ date: '2024-01-01' }, 1, 20)
```

#### Vendas Recorrentes (Recurring Sales)

##### Criando uma Venda Recorrente

```ruby
venda_recorrente = Conexa::RecurringSale.new(
  customer_id: customer_id,
  plan_id:     plan_id,
  start_date:  '2024-01-01'
).create
```

##### Recuperando uma Venda Recorrente

```ruby
venda_recorrente = Conexa::RecurringSale.find(recurring_sale_id)
```

##### Excluindo uma Venda Recorrente

```ruby
Conexa::RecurringSale.destroy(recurring_sale_id)
```

##### Listando Vendas Recorrentes

```ruby
vendas_recorrentes = Conexa::RecurringSale.find({ active: true }, 1, 20)
```

### Métodos Comuns

Cada recurso fornece métodos comuns:

- `new(params).create` - Criar um novo registro.
- `find(id)` - Recuperar um registro específico por ID.
- `find(hash_filtros, page, size)` - Recuperar registros com filtros e paginação.
- `destroy(id)` - Excluir um registro por ID.
- `find(id).destroy` - Buscar e excluir um registro.

### Operações Específicas de Recursos

Alguns recursos podem oferecer métodos adicionais específicos de sua funcionalidade. Consulte a [Documentação da API Conexa](https://conexa.app/api-docs) para informações detalhadas.

## Validando Webhooks

Para garantir que todos os webhooks recebidos são enviados pela Conexa, você deve validar a assinatura fornecida no cabeçalho HTTP `X-Signature`. Você pode validá-la usando o payload bruto e a assinatura.

```ruby
valido = Conexa::Webhook.valid_request_signature?(raw_payload, signature)
```

### Exemplo com Rails

Se você está usando Rails, pode validar o webhook no seu controller:

```ruby
class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def receive
    if webhook_valido?
      # Processe seu código aqui
      # O payload do webhook está em params
    else
      render_resposta_webhook_invalido
    end
  end

  private

  def webhook_valido?
    raw_payload = request.raw_post
    signature   = request.headers['X-Signature']
    Conexa::Webhook.valid_request_signature?(raw_payload, signature)
  end

  def render_resposta_webhook_invalido
    render json: { error: 'Webhook inválido' }, status: 400
  end
end
```

## Funcionalidades Não Documentadas

Esta gem é estável, mas está em desenvolvimento contínuo. Este README fornece uma visão geral rápida de suas principais funcionalidades.

Você pode explorar o código-fonte para ver todos os [recursos suportados](lib/conexa/resources). Continuaremos a documentar e adicionar suporte para todas as funcionalidades listadas na [Documentação da API Conexa](https://conexa.app/api-docs).

Sinta-se à vontade para contribuir enviando pull requests.

## Suporte

Se você tiver problemas ou sugestões, por favor abra uma issue [aqui](https://github.com/guilhermegazzinelli/conexa-ruby/issues).

## Licença

Este projeto está licenciado sob a [Licença MIT](LICENSE).

## Aviso Legal

Esta gem é baseada nas definições da API Conexa disponíveis na [coleção Postman oficial](https://web.postman.co/workspace/8e1887b1-bef9-4e36-848f-2b6774a81022/collection/33452984-58f4d7ab-d280-4aac-8578-8366988ff7af). Atualmente suporta apenas autenticação via chave de API.

Para mais informações sobre a API Conexa, visite a [documentação oficial](https://conexa.app/).
