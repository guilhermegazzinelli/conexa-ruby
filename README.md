# Conexa Ruby

[![Gem Version](https://badge.fury.io/rb/conexa.svg)](https://badge.fury.io/rb/conexa)
[![CI](https://github.com/guilhermegazzinelli/conexa-ruby/actions/workflows/main.yml/badge.svg)](https://github.com/guilhermegazzinelli/conexa-ruby/actions)

Ruby client for the [Conexa API](https://conexa.app/) - Billing and subscription management platform.

**[Versão em Português](README_pt-BR.md)**

## Installation

Add to your Gemfile:

```ruby
gem 'conexa'
```

Or install directly:

```shell
gem install conexa
```

## Configuration

```ruby
Conexa.configure do |config|
  config.api_host  = 'https://your-company.conexa.app'  # your tenant
  config.api_token = 'YOUR_API_TOKEN'                   # Application Token from Conexa
end
```

### Authentication Methods

1. **Application Token** (recommended): Created in Conexa at **Config > Integrações > API / Token**
2. **Username/Password**: Use the `/auth` endpoint to get a JWT token

### Read-only mode

This gem talks to a billing system: settling a charge moves money and can issue
an NF-e. When you only mean to read — auditing, reporting, investigating — turn
writing off and let the gem refuse instead of trusting yourself to be careful.

```ruby
Conexa.configure { |config| config.read_only = true }

Conexa::Charge.all(status: 'pending')   # fine
Conexa::Charge.settle(789)              # raises Conexa::ReadOnlyError
```

Set `CONEXA_READ_ONLY=1` in the environment to default it on — useful in CI, or
in any shell where you would rather not discover you were pointed at production.

For a single block, without reconfiguring the client:

```ruby
Conexa.read_only do
  report = Conexa::Charge.all(limit: 100)   # anything here is read-only
end
```

The guard runs before the request leaves the process, so a blocked call never
reaches your tenant. `GET` is allowed, and so is `POST /auth` — without it
read-only mode could not obtain a token.

**The block form is fiber-local.** It does not reach a `Thread` or `Fiber`
spawned inside it, nor external iteration on an `Enumerator`. For anything
concurrent use `config.read_only` (or `CONEXA_READ_ONLY`), which is global.

## Quick Start

```ruby
require 'conexa'

Conexa.configure do |config|
  config.api_host  = 'https://mycompany.conexa.app'
  config.api_token = ENV['CONEXA_API_TOKEN']
end

# List customers
customers = Conexa::Customer.all
customers.data.each do |customer|
  puts "#{customer.customer_id}: #{customer.name}"
end

# Get a specific customer
customer = Conexa::Customer.find(127)
puts customer.name
puts customer.address.city
```

## Convention

This gem follows Ruby conventions:

- **Parameters**: Use `snake_case` when calling methods - the gem automatically converts to `camelCase` for the API
- **Responses**: API responses are converted from `camelCase` to `snake_case`
- **Backwards compatibility**: `camelCase` methods are aliased (e.g., `customer.customer_id` and `customer.customerId` both work)

## Resources

### Customer

```ruby
# Create a customer (Legal Person - PJ)
customer = Conexa::Customer.create(
  company_id: 3,
  name: 'Empresa ABC Ltda',
  trade_name: 'ABC',
  cell_number: '11999998888',
  has_login_access: false,
  legal_person: {
    cnpj: '99.557.155/0001-90',
    foundation_date: '2020-06-12'
  },
  address: {
    zip_code: '13058-111',
    state: 'SP',
    city: 'Campinas',
    street: 'Rua Principal',
    number: '100',
    neighborhood: 'Centro'
  },
  phones: ['(11) 3333-4444'],
  emails_message: ['contato@empresa.com'],
  emails_financial_messages: ['financeiro@empresa.com']
)
puts customer.id  # => 114

# Create a customer (Natural Person - PF)
customer = Conexa::Customer.create(
  company_id: 3,
  name: 'João Silva',
  natural_person: {
    cpf: '516.079.209-05',
    birth_date: '1990-05-15',
    profession: 'Developer'
  },
  has_login_access: true,
  login: 'joao.silva',
  password: 'SecurePass123!'
)

# Retrieve customer
customer = Conexa::Customer.find(127)
customer.name           # => "Empresa ABC Ltda"
customer.company_id     # => 3
customer.is_active      # => true
customer.address.city   # => "Campinas"
customer.legal_person['cnpj']  # => "99.557.155/0001-90"

# Update customer
customer = Conexa::Customer.find(127)
customer.name = 'New Name'
customer.cell_number = '11888887777'
customer.save

# List customers with filters (new pagination)
customers = Conexa::Customer.all(
  company_id: [3],
  is_active: true,
  limit: 20
)

# Sub-resources (instance methods)
customer = Conexa::Customer.find(127)
customer.persons     # => persons for this customer
customer.contracts   # => contracts for this customer
customer.charges     # => charges for this customer

# Sub-resources (class methods — saves a request)
Conexa::Customer.persons(127)
Conexa::Customer.contracts(127)
Conexa::Customer.charges(127)
```

### Contract

```ruby
# Create a contract
contract = Conexa::Contract.create(
  customer_id: 127,
  plan_id: 5,
  start_date: '2024-01-01',
  payment_day: 10,
  invoicing_method_id: 1
)

# Create contract with custom items
contract = Conexa::Contract.create_with_products(
  customer_id: 127,
  start_date: '2024-01-01',
  payment_day: 10,
  items: [
    { product_id: 101, quantity: 1, amount: 299.90 },
    { product_id: 102, quantity: 2, amount: 49.90 }
  ]
)

# Retrieve contract
contract = Conexa::Contract.find(456)

# Cancel contract
Conexa::Contract.cancel(456, cancel_date: '2024-12-31')
```

### Sale (One-time)

```ruby
# Create a one-time sale
sale = Conexa::Sale.create(
  customer_id: 450,
  requester_id: 458,
  product_id: 2521,
  quantity: 1,
  amount: 80.99,
  reference_date: '2024-09-24T17:24:00-03:00',
  notes: 'WhatsApp order'
)
puts sale.id  # => 188481

# Retrieve sale
sale = Conexa::Sale.find(188510)
sale.status         # => "notBilled"
sale.amount         # => 80.99
sale.discount_value # => 69.21

# List sales
sales = Conexa::Sale.all(
  customer_id: [450, 216],
  status: 'notBilled',
  date_from: '2024-01-01',
  date_to: '2024-12-31',
  page: 1,
  size: 20
)

# Update sale
sale = Conexa::Sale.find(188510)
sale.quantity = 2
sale.amount = 150.00
sale.save

# Delete sale (only if not billed)
Conexa::Sale.destroy(188510)
```

### Recurring Sale

```ruby
# Create recurring sale
recurring = Conexa::RecurringSale.create(
  customer_id: 127,
  product_id: 101,
  quantity: 1,
  start_date: '2024-01-01'
)

# List recurring sales for a contract
Conexa::RecurringSale.all(contract_id: 456)
```

### Charge

```ruby
# Retrieve charge
charge = Conexa::Charge.find(789)
charge.status     # => "paid"
charge.amount     # => 299.90
charge.due_date   # => "2024-02-10"

# List charges
charges = Conexa::Charge.all(
  customer_id: [127],
  status: 'pending',
  due_date_from: '2024-01-01',
  due_date_to: '2024-12-31'
)

# Cancel charge
Conexa::Charge.cancel(789)

# Send charge by email
Conexa::Charge.send_email(789)
```

### Bill (Invoice)

```ruby
# Retrieve bill
bill = Conexa::Bill.find(101)

# List bills
bills = Conexa::Bill.all(
  customer_id: [127],
  page: 1,
  size: 50
)
```

### Plan

```ruby
# List plans
plans = Conexa::Plan.all(company_id: [3])

# Retrieve plan
plan = Conexa::Plan.find(5)
plan.name   # => "Plano Básico"
plan.price  # => 99.90
```

### Product

```ruby
# List products
products = Conexa::Product.all(company_id: [3], limit: 50)

# Retrieve product
product = Conexa::Product.find(101)

# Create product
product = Conexa::Product.create(name: 'Novo Produto', company_id: 3)

# Delete product
Conexa::Product.destroy(101)
```

### Receiving Method

```ruby
methods = Conexa::ReceivingMethod.all(limit: 50)
method = Conexa::ReceivingMethod.find(11)
method.name  # => "Cartão de Crédito"
```

### Payment Method

```ruby
methods = Conexa::PaymentMethod.all(limit: 50)
method = Conexa::PaymentMethod.find(2)
```

### Bill Category / Subcategory

```ruby
categories = Conexa::BillCategory.all(limit: 50)
subcategories = Conexa::BillSubcategory.all(limit: 50)
```

### Cost Center

```ruby
centers = Conexa::CostCenter.all(limit: 50)
center = Conexa::CostCenter.find(11)
```

### Account

```ruby
accounts = Conexa::Account.all(limit: 50)
account = Conexa::Account.find(23)
```

### Service Category

```ruby
categories = Conexa::ServiceCategory.all(limit: 50)
category = Conexa::ServiceCategory.find(1)
```

### Room Booking

```ruby
# List bookings
bookings = Conexa::RoomBooking.all(limit: 20)

# Create booking
booking = Conexa::RoomBooking.create(room_id: 5, customer_id: 127)

# Cancel booking
Conexa::RoomBooking.cancel(143063)

# Checkin
Conexa::RoomBooking.checkin(room_id: 5, customer_id: 127)
```

### Credit Card

```ruby
# Add credit card to customer
card = Conexa::CreditCard.create(
  customer_id: 127,
  card_number: '4111111111111111',
  cardholder_name: 'JOAO SILVA',
  expiration_month: '12',
  expiration_year: '2025',
  cvv: '123'
)

# List customer's cards
cards = Conexa::CreditCard.all(customer_id: 127)

# Delete card
Conexa::CreditCard.destroy(card_id)
```

### Company (Unit)

```ruby
# List companies/units
companies = Conexa::Company.all

# Retrieve company
company = Conexa::Company.find(3)
company.name      # => "Matriz"
company.document  # => "12.345.678/0001-90"
```

## Pagination

### New Pagination (recommended) — `limit`/`offset`/`hasNext`

```ruby
result = Conexa::Customer.all(limit: 50)

result.data                    # Array of customers
result.pagination.limit        # => 50
result.pagination.offset       # => 0
result.has_next?               # => true/false

# Iterate through all pages using next_page
result = Conexa::Customer.all(limit: 50)
loop do
  result.data.each { |customer| process(customer) }
  break unless result.has_next?
  result = result.next_page
end

# Or manually with offset
offset = 0
loop do
  result = Conexa::Customer.all(limit: 50, offset: offset)
  result.data.each { |customer| process(customer) }
  break unless result.has_next?
  offset += 50
end
```

### Legacy Pagination (deprecated — will be removed 2026-08-01)

```ruby
# Still works but emits a deprecation warning
result = Conexa::Customer.all(page: 1, size: 20)
result.pagination.current_page    # => 1
result.pagination.total_pages     # => 10
```

### Migration Guide: Legacy → New Pagination

The legacy `page`/`size` pagination is deprecated and will be removed on **2026-08-01**. Follow these steps to migrate:

#### 1. Replace `page`/`size` with `limit`/`offset`

```ruby
# BEFORE (legacy — deprecated)
result = Conexa::Customer.all(page: 1, size: 50)
result = Conexa::Customer.all(page: 2, size: 50)

# AFTER (new)
result = Conexa::Customer.all(limit: 50)               # offset defaults to 0
result = Conexa::Customer.all(limit: 50, offset: 50)   # second page
```

**Conversion formula:** `offset = (page - 1) * size`

#### 2. Update pagination metadata access

```ruby
# BEFORE (legacy)
result.pagination  # => { "page" => 1, "size" => 50, "total" => 150 }
total_pages = (result.pagination["total"].to_f / size).ceil

# AFTER (new)
result.pagination.limit      # => 50
result.pagination.offset     # => 0
result.pagination.has_next   # => true/false
```

#### 3. Update iteration loops

```ruby
# BEFORE (legacy)
page = 1
loop do
  result = Conexa::Customer.all(page: page, size: 100)
  break if result.empty?
  result.data.each { |c| process(c) }
  page += 1
end

# AFTER (new — using next_page)
result = Conexa::Customer.all(limit: 100)
loop do
  result.data.each { |c| process(c) }
  break unless result.has_next?
  result = result.next_page
end
```

#### 4. Remove positional arguments

```ruby
# BEFORE (legacy positional args)
Conexa::Customer.all(2, 50)           # page 2, size 50
Conexa::Customer.find_by({}, 1, 20)   # page 1, size 20

# AFTER (new keyword args)
Conexa::Customer.all(limit: 50, offset: 50)
Conexa::Customer.find_by(limit: 20)
```

#### Quick reference

| Legacy | New |
|---|---|
| `page: 1, size: 50` | `limit: 50` (offset defaults to 0) |
| `page: N, size: S` | `limit: S, offset: (N-1)*S` |
| `pagination["total"]` | `pagination.has_next` |
| `pagination["page"]` | `pagination.offset` |
| Positional `(page, size)` | Keyword `limit:`, `offset:` |

## Error Handling

```ruby
begin
  customer = Conexa::Customer.create(name: '')
rescue Conexa::ValidationError => e
  # Field validation errors (400)
  puts e.message
rescue Conexa::NotFound => e
  # Resource not found (404)
  puts e.message
rescue Conexa::ResponseError => e
  # API response error (4xx/5xx)
  puts e.message
rescue Conexa::RequestError => e
  # Request-level error (invalid params, etc.)
  puts e.message
rescue Conexa::ConnectionError => e
  # Network/connection error
  puts e.message
rescue Conexa::ConexaError => e
  # Generic Conexa error (catch-all)
  puts e.message
end
```

## Rate Limiting

The Conexa API has a limit of **100 requests per minute** (changing to **60 requests per minute** on 2026-04-27). Response headers include:

- `X-Rate-Limit-Limit`: Maximum requests in 60s
- `X-Rate-Limit-Remaining`: Remaining requests in 60s
- `X-Rate-Limit-Reset`: Seconds until reset

## Documentation

- [Conexa Website](https://conexa.app/)
- [API Documentation](https://conexa.app/api-docs)
- [Postman Collection](https://documenter.getpostman.com/view/25182821/2s93RZMpcB)
- [Discord Community](https://discord.gg/zW28sJh7Nz) - Conexa for Developers
- [REFERENCE.md](REFERENCE.md) - Complete API reference for LLMs/AI agents

## Development

```bash
# Install dependencies
bundle install

# Run tests
bundle exec rspec

# Run linter
bundle exec rubocop
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -am 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Create a Pull Request

## License

MIT License. See [LICENSE](LICENSE) for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for release history.
