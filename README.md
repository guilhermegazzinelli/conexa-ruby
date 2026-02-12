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
  config.subdomain = 'YOUR_SUBDOMAIN'  # your-company.conexa.app
  config.api_token = 'YOUR_API_TOKEN'  # Application Token from Conexa
end
```

### Authentication Methods

1. **Application Token** (recommended): Created in Conexa at **Config > Integrações > API / Token**
2. **Username/Password**: Use the `/auth` endpoint to get a JWT token

## Quick Start

```ruby
require 'conexa'

Conexa.configure do |config|
  config.subdomain = 'mycompany'
  config.api_token = ENV['CONEXA_API_TOKEN']
end

# List customers
customers = Conexa::Customer.list
customers.data.each do |customer|
  puts "#{customer.customerId}: #{customer.name}"
end

# Get a specific customer
customer = Conexa::Customer.retrieve(127)
puts customer.name
puts customer.address.city
```

## Resources

### Customer

```ruby
# Create a customer (Legal Person - PJ)
customer = Conexa::Customer.create(
  companyId: 3,
  name: 'Empresa ABC Ltda',
  tradeName: 'ABC',
  cellNumber: '11999998888',
  hasLoginAccess: false,
  legalPerson: {
    cnpj: '99.557.155/0001-90',
    foundationDate: '2020-06-12'
  },
  address: {
    zipCode: '13058-111',
    state: 'SP',
    city: 'Campinas',
    street: 'Rua Principal',
    number: '100',
    neighborhood: 'Centro'
  },
  phones: ['(11) 3333-4444'],
  emailsMessage: ['contato@empresa.com'],
  emailsFinancialMessages: ['financeiro@empresa.com']
)
puts customer.id  # => 114

# Create a customer (Natural Person - PF)
customer = Conexa::Customer.create(
  companyId: 3,
  name: 'João Silva',
  naturalPerson: {
    cpf: '516.079.209-05',
    birthDate: '1990-05-15',
    profession: 'Developer'
  },
  hasLoginAccess: true,
  login: 'joao.silva',
  password: 'SecurePass123!'
)

# Retrieve customer
customer = Conexa::Customer.retrieve(127)
customer.name           # => "Empresa ABC Ltda"
customer.companyId      # => 3
customer.isActive       # => true
customer.address.city   # => "Campinas"
customer.legalPerson.cnpj  # => "99.557.155/0001-90"

# Update customer
Conexa::Customer.update(127, name: 'New Name', cellNumber: '11888887777')

# List customers with filters
customers = Conexa::Customer.list(
  companyId: [3],
  isActive: true,
  page: 1,
  size: 20
)
```

### Contract

```ruby
# Create a contract
contract = Conexa::Contract.create(
  customerId: 127,
  planId: 5,
  startDate: '2024-01-01',
  paymentDay: 10,
  invoicingMethodId: 1
)

# Create contract with custom items
contract = Conexa::Contract.create_with_products(
  customerId: 127,
  startDate: '2024-01-01',
  paymentDay: 10,
  items: [
    { productId: 101, quantity: 1, amount: 299.90 },
    { productId: 102, quantity: 2, amount: 49.90 }
  ]
)

# Retrieve contract
contract = Conexa::Contract.retrieve(456)

# Cancel contract
Conexa::Contract.cancel(456, cancelDate: '2024-12-31')
```

### Sale (One-time)

```ruby
# Create a one-time sale
sale = Conexa::Sale.create(
  customerId: 450,
  requesterId: 458,
  productId: 2521,
  quantity: 1,
  amount: 80.99,
  referenceDate: '2024-09-24T17:24:00-03:00',
  notes: 'WhatsApp order'
)
puts sale.id  # => 188481

# Retrieve sale
sale = Conexa::Sale.retrieve(188510)
sale.status         # => "notBilled"
sale.amount         # => 80.99
sale.discountValue  # => 69.21

# List sales
sales = Conexa::Sale.list(
  customerId: [450, 216],
  status: 'notBilled',
  dateFrom: '2024-01-01',
  dateTo: '2024-12-31',
  page: 1,
  size: 20
)

# Update sale
Conexa::Sale.update(188510, quantity: 2, amount: 150.00)

# Delete sale (only if not billed)
Conexa::Sale.delete(188510)
```

### Recurring Sale

```ruby
# Create recurring sale
recurring = Conexa::RecurringSale.create(
  customerId: 127,
  productId: 101,
  quantity: 1,
  startDate: '2024-01-01'
)

# List recurring sales for a contract
Conexa::RecurringSale.list(contractId: 456)
```

### Charge

```ruby
# Retrieve charge
charge = Conexa::Charge.retrieve(789)
charge.status      # => "paid"
charge.amount      # => 299.90
charge.dueDate     # => "2024-02-10"

# List charges
charges = Conexa::Charge.list(
  customerId: [127],
  status: 'pending',
  dueDateFrom: '2024-01-01',
  dueDateTo: '2024-12-31'
)

# Cancel charge
Conexa::Charge.cancel(789)

# Send charge by email
Conexa::Charge.send_email(789)
```

### Bill (Invoice)

```ruby
# Retrieve bill
bill = Conexa::Bill.retrieve(101)

# List bills
bills = Conexa::Bill.list(
  customerId: [127],
  page: 1,
  size: 50
)
```

### Plan

```ruby
# List plans
plans = Conexa::Plan.list(companyId: [3])

# Retrieve plan
plan = Conexa::Plan.retrieve(5)
plan.name   # => "Plano Básico"
plan.price  # => 99.90
```

### Product

```ruby
# List products
products = Conexa::Product.list(companyId: [3])

# Retrieve product
product = Conexa::Product.retrieve(101)
```

### Credit Card

```ruby
# Add credit card to customer
card = Conexa::CreditCard.create(
  customerId: 127,
  cardNumber: '4111111111111111',
  cardholderName: 'JOAO SILVA',
  expirationMonth: '12',
  expirationYear: '2025',
  cvv: '123'
)

# List customer's cards
cards = Conexa::CreditCard.list(customerId: 127)

# Delete card
Conexa::CreditCard.delete(cardId)
```

### Company (Unit)

```ruby
# List companies/units
companies = Conexa::Company.list

# Retrieve company
company = Conexa::Company.retrieve(3)
company.name      # => "Matriz"
company.document  # => "12.345.678/0001-90"
```

## Pagination

All list endpoints return paginated results:

```ruby
result = Conexa::Customer.list(page: 1, size: 20)

result.data           # Array of customers
result.pagination.currentPage   # => 1
result.pagination.totalPages    # => 10
result.pagination.totalItems    # => 195
result.pagination.itemPerPage   # => 20

# Iterate through pages
loop do
  result.data.each { |customer| process(customer) }
  break if result.pagination.currentPage >= result.pagination.totalPages
  result = Conexa::Customer.list(page: result.pagination.currentPage + 1)
end
```

## Error Handling

```ruby
begin
  customer = Conexa::Customer.create(name: '')
rescue Conexa::ValidationError => e
  # Field validation errors (400)
  e.errors.each do |error|
    puts "#{error['field']}: #{error['messages'].join(', ')}"
  end
rescue Conexa::AuthenticationError => e
  # Authentication required (401)
  puts e.message
rescue Conexa::AuthorizationError => e
  # Not authorized (403)
  puts e.message
rescue Conexa::NotFoundError => e
  # Resource not found (404)
  puts e.message
rescue Conexa::UnprocessableError => e
  # Business logic error (422)
  e.errors.each do |error|
    puts "#{error['code']}: #{error['message']}"
  end
rescue Conexa::RateLimitError => e
  # Too many requests (429)
  puts "Rate limit exceeded. Retry after #{e.retry_after} seconds"
rescue Conexa::ApiError => e
  # Generic API error
  puts "Error #{e.status}: #{e.message}"
end
```

## Rate Limiting

The Conexa API has a limit of **100 requests per minute**. Response headers include:

- `X-Rate-Limit-Limit`: Maximum requests in 60s
- `X-Rate-Limit-Remaining`: Remaining requests in 60s
- `X-Rate-Limit-Reset`: Seconds until reset

## Documentation

- [Conexa Website](https://conexa.app/)
- [API Documentation](https://conexa.app/api-docs)
- [Postman Collection](https://documenter.getpostman.com/view/25182821/2s93RZMpcB)
- [Discord Community](https://discord.gg/zW28sJh7Nz) - Conexa for Developers

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
