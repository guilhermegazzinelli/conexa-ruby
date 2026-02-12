# Conexa Ruby - LLM Reference

> Ruby client for the Conexa API - Brazilian billing and subscription management platform.

## Overview

Conexa is a Brazilian SaaS platform for **recurring billing**, **subscription management**, and **financial operations**. This gem provides a Ruby interface to their REST API v2.

**Key concepts:**
- **Customer** - Client (PF or PJ) who receives invoices
- **Contract** - Recurring billing agreement with a plan
- **Charge** - Individual invoice/boleto generated for payment
- **Sale** - One-time sale (not recurring)
- **RecurringSale** - Recurring sale item within a contract
- **Plan** - Predefined pricing plan with products
- **Product** - Billable item/service

## Installation

```ruby
# Gemfile
gem 'conexa', '~> 0.0.6'

# Or install directly
gem install conexa
```

## Configuration

```ruby
Conexa.configure do |config|
  config.api_host = 'https://api.conexa.com.br'  # or sandbox URL
  config.api_token = 'your_api_token_here'
end

# Rails: use generator
rails generate conexa:install
# Creates config/initializers/conexa.rb
```

## Convention: snake_case

This gem follows Ruby/Rails conventions. Use **snake_case** for all parameters - the gem automatically converts to camelCase for the API.

```ruby
# ✅ Correct - snake_case
Conexa::Customer.create(
  company_id: 3,
  legal_person: { cnpj: '99.557.155/0001-90' }
)

# ❌ Avoid - camelCase (works but not idiomatic)
Conexa::Customer.create(
  companyId: 3,
  legalPerson: { cnpj: '99.557.155/0001-90' }
)
```

Response attributes are also accessible in snake_case:
```ruby
customer = Conexa::Customer.find(127)
customer.customer_id      # => 127
customer.company_id       # => 3
customer.is_active        # => true
customer.legal_person     # => { cnpj: '...' }
```

## Resources

### Customer

Manages clients (pessoas físicas ou jurídicas).

```ruby
# Create customer (Pessoa Jurídica)
customer = Conexa::Customer.create(
  company_id: 3,
  name: 'Empresa ABC Ltda',
  legal_person: { cnpj: '99.557.155/0001-90' },
  emails_message: ['contato@abc.com.br'],
  phones: ['31999998888']
)

# Create customer (Pessoa Física)
customer = Conexa::Customer.create(
  company_id: 3,
  name: 'João Silva',
  natural_person: { cpf: '123.456.789-00' }
)

# Find by ID
customer = Conexa::Customer.find(127)
customer.name             # => "Empresa ABC Ltda"
customer.customer_id      # => 127
customer.is_active        # => true
customer.address          # => Address object or nil

# List with filters
customers = Conexa::Customer.all(
  company_id: [3],
  is_active: true,
  page: 1,
  size: 50
)

# Update
customer.name = 'Novo Nome'
customer.save

# Delete
customer.destroy
# or
Conexa::Customer.destroy(127)
```

**Customer attributes:**
- `customer_id` - ID
- `company_id` - Unit/company ID
- `name` - Full name
- `trade_name` - Trade name (optional)
- `has_login_access` - Has portal access
- `is_active` - Active status
- `is_blocked` - Blocked status
- `is_juridical_person` - Is PJ (legal person)
- `is_foreign` - Is foreigner
- `address` - Address object
- `legal_person` - PJ data (cnpj, etc)
- `natural_person` - PF data (cpf, etc)
- `phones` - Array of phones
- `emails_message` - General emails
- `emails_financial_messages` - Financial emails
- `tags_id` - Tag IDs
- `created_at` - Creation timestamp

---

### Contract

Manages recurring billing contracts.

```ruby
# Create contract
contract = Conexa::Contract.create(
  customer_id: 127,
  plan_id: 5,
  start_date: '2024-01-01',
  payment_day: 10,
  invoicing_method_id: 1
)

# Create with custom products (no plan)
contract = Conexa::Contract.create_with_products(
  customer_id: 127,
  start_date: '2024-01-01',
  payment_day: 10,
  items: [
    { product_id: 100, quantity: 1, amount: 99.90 },
    { product_id: 101, quantity: 2, amount: 50.00 }
  ]
)

# Find contract
contract = Conexa::Contract.find(456)
contract.status       # => "active"
contract.plan_id      # => 5
contract.payment_day  # => 10

# List contracts
contracts = Conexa::Contract.all(
  customer_id: [127],
  status: 'active'
)

# End/terminate contract
contract.end_contract(end_date: '2024-12-31', reason: 'Cliente solicitou')
# or
Conexa::Contract.end_contract(456, end_date: '2024-12-31')

# Update
contract.payment_day = 15
contract.save
```

**Contract attributes:**
- `contract_id` - ID
- `customer_id` - Customer ID
- `plan_id` - Plan ID (optional)
- `status` - Status (active, ended, cancelled)
- `start_date` - Start date
- `end_date` - End date (if terminated)
- `payment_day` - Day of month for billing (1-28)

---

### Charge

Manages invoices/boletos.

```ruby
# Find charge
charge = Conexa::Charge.find(789)
charge.status      # => "pending"
charge.amount      # => 199.90
charge.due_date    # => "2024-02-10"

# List charges
charges = Conexa::Charge.all(
  customer_id: [127],
  status: 'pending',
  due_date_from: '2024-01-01',
  due_date_to: '2024-01-31'
)

# Settle (mark as paid)
charge.settle(payment_date: '2024-02-05', payment_value: 199.90)
# or
Conexa::Charge.settle(789, payment_date: '2024-02-05')

# Get PIX QR Code
pix = charge.pix
pix.qr_code        # => "00020126..."
pix.qr_code_image  # => Base64 image

# Send email notification
charge.send_email
# or
Conexa::Charge.send_email(789)

# Cancel charge
charge.cancel
# or
Conexa::Charge.cancel(789)
```

**Charge attributes:**
- `charge_id` - ID
- `customer_id` - Customer ID
- `status` - Status (pending, paid, overdue, cancelled)
- `amount` - Amount due
- `due_date` - Due date

**Methods:**
- `settle(params)` - Mark as paid
- `pix` - Get PIX payment data
- `send_email` - Send notification
- `cancel` - Cancel charge

---

### Sale

Manages one-time sales.

```ruby
# Create sale
sale = Conexa::Sale.create(
  customer_id: 450,
  product_id: 2521,
  quantity: 1,
  amount: 80.99,
  reference_date: '2024-01-15',
  notes: 'Venda avulsa'
)

# Find sale
sale = Conexa::Sale.find(1234)
sale.status   # => "notBilled"
sale.amount   # => 80.99

# List sales
sales = Conexa::Sale.all(
  customer_id: [450],
  status: 'notBilled',
  reference_date_from: '2024-01-01',
  reference_date_to: '2024-01-31'
)

# Update (only if notBilled)
sale.amount = 90.00
sale.save

# Delete
sale.destroy
```

**Sale statuses:**
- `notBilled` - Not yet billed (editable)
- `billed` - Included in a charge
- `paid` - Paid
- `cancelled` - Cancelled
- `deductedFromQuota` - Deducted from quota
- `billedCancelled` - Billing cancelled
- `billedNegociated` - Negotiated
- `partiallyPaid` - Partially paid

---

### RecurringSale

Manages recurring items within contracts.

```ruby
# Find recurring sale
rs = Conexa::RecurringSale.find(555)

# List recurring sales
recurring = Conexa::RecurringSale.all(
  contract_id: [456],
  status: 'active'
)

# End recurring sale
rs.end_recurring_sale(end_date: '2024-12-31')
# or
Conexa::RecurringSale.end_recurring_sale(555, end_date: '2024-12-31')
```

---

### Plan

Read-only resource for pricing plans.

```ruby
# Find plan
plan = Conexa::Plan.find(5)
plan.name   # => "Plano Básico"
plan.amount # => 99.90

# List plans
plans = Conexa::Plan.all(company_id: [3])
```

**Note:** Plans cannot be created/updated via API. Use Conexa dashboard.

---

### Product

Read-only resource for billable products/services.

```ruby
# Find product
product = Conexa::Product.find(100)
product.name  # => "Mensalidade"

# List products
products = Conexa::Product.all(company_id: [3])
```

**Note:** Products cannot be created/updated via API. Use Conexa dashboard.

---

### Bill

Read-only resource for financial bills (contas a pagar).

```ruby
# Find bill
bill = Conexa::Bill.find(321)

# List bills
bills = Conexa::Bill.all(company_id: [3])
```

---

### Company

Manages units/companies within the account.

```ruby
# Find company
company = Conexa::Company.find(3)

# List companies
companies = Conexa::Company.all
```

---

### Supplier

Manages suppliers (fornecedores).

```ruby
# Find supplier
supplier = Conexa::Supplier.find(50)

# List suppliers
suppliers = Conexa::Supplier.all(company_id: [3])

# Create supplier
supplier = Conexa::Supplier.create(
  company_id: 3,
  name: 'Fornecedor XYZ'
)
```

---

### CreditCard

Manages customer credit cards.

```ruby
# Find credit card
card = Conexa::CreditCard.find(99)

# Create (tokenized)
card = Conexa::CreditCard.create(
  customer_id: 127,
  token: 'card_token_from_gateway'
)
```

---

### Person

Manages requesters (solicitantes) for a customer. Limited API access.

```ruby
# Create person for customer
person = Conexa::Person.create(
  customer_id: 127,
  name: 'Maria Solicitante',
  email: 'maria@empresa.com'
)
```

---

## Common Patterns

### Pagination

All `#all` and `#find_by` methods support pagination:

```ruby
# Page 1, 50 items per page
result = Conexa::Customer.all(page: 1, size: 50)

result.data        # => Array of customers
result.pagination  # => { "page" => 1, "size" => 50, "total" => 150 }
result.empty?      # => false

# Iterate all pages
page = 1
loop do
  result = Conexa::Customer.all(page: page, size: 100)
  break if result.empty?
  
  result.each { |customer| process(customer) }
  page += 1
end
```

### Result Object

API calls return `Conexa::Result` objects:

```ruby
result = Conexa::Customer.all
result.data        # Array of objects
result.pagination  # Pagination info
result.empty?      # Check if no results
result.each { }    # Iterate (delegates to data)
result.first       # First item
result.count       # Number of items
```

### Error Handling

```ruby
begin
  customer = Conexa::Customer.find(999999)
rescue Conexa::NotFound => e
  puts "Customer not found: #{e.message}"
rescue Conexa::ValidationError => e
  puts "Validation failed: #{e.errors}"
rescue Conexa::ConnectionError => e
  puts "Connection failed: #{e.message}"
rescue Conexa::ResponseError => e
  puts "API error: #{e.message}"
end
```

**Error classes:**
- `Conexa::NotFound` - Resource not found (404)
- `Conexa::ValidationError` - Validation failed (422)
- `Conexa::ConnectionError` - Network error
- `Conexa::ResponseError` - Generic API error
- `Conexa::RequestError` - Invalid request parameters
- `Conexa::MissingCredentialsError` - Token not configured

### Filters

Common filter parameters across resources:

```ruby
# Date ranges
Conexa::Charge.all(
  due_date_from: '2024-01-01',
  due_date_to: '2024-01-31'
)

# Multiple IDs
Conexa::Customer.all(company_id: [1, 2, 3])

# Status filters
Conexa::Contract.all(status: 'active')
Conexa::Sale.all(status: 'notBilled')

# Combined
Conexa::Charge.all(
  customer_id: [127],
  status: 'pending',
  due_date_from: '2024-01-01',
  page: 1,
  size: 100
)
```

---

## Model Methods Summary

| Resource | find | all | create | save | destroy | Special Methods |
|----------|------|-----|--------|------|---------|-----------------|
| Customer | ✅ | ✅ | ✅ | ✅ | ✅ | - |
| Contract | ✅ | ✅ | ✅ | ✅ | ✅ | end_contract |
| Charge | ✅ | ✅ | ❌ | ❌ | ❌ | settle, pix, cancel, send_email |
| Sale | ✅ | ✅ | ✅ | ✅ | ✅ | - |
| RecurringSale | ✅ | ✅ | ✅ | ✅ | ✅ | end_recurring_sale |
| Plan | ✅ | ✅ | ❌ | ❌ | ❌ | - |
| Product | ✅ | ✅ | ❌ | ❌ | ❌ | - |
| Bill | ✅ | ✅ | ❌ | ❌ | ❌ | - |
| Company | ✅ | ✅ | ✅ | ✅ | ✅ | - |
| Supplier | ✅ | ✅ | ✅ | ✅ | ✅ | - |
| CreditCard | ✅ | ❌ | ✅ | ✅ | ✅ | - |
| Person | ❌ | ❌ | ✅ | ✅ | ✅ | - |

---

## Version History

- **v0.0.6** - Fix nil guard in camelize_hash, fix Result#empty? delegation
- **v0.0.5** - Initial public release

## Links

- **RubyGems:** https://rubygems.org/gems/conexa
- **GitHub:** https://github.com/guilhermegazzinelli/conexa-ruby
- **Conexa API Docs:** https://documenter.getpostman.com/view/25182821/2s93RZMpcB
