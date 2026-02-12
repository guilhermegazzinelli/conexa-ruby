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

## Resources

### Customer

Manages clients (pessoas físicas ou jurídicas).

```ruby
# Create customer (Pessoa Jurídica)
customer = Conexa::Customer.create(
  companyId: 3,
  name: 'Empresa ABC Ltda',
  legalPerson: { cnpj: '99.557.155/0001-90' },
  emailsMessage: ['contato@abc.com.br'],
  phones: ['31999998888']
)

# Create customer (Pessoa Física)
customer = Conexa::Customer.create(
  companyId: 3,
  name: 'João Silva',
  naturalPerson: { cpf: '123.456.789-00' }
)

# Find by ID
customer = Conexa::Customer.find(127)
customer.name           # => "Empresa ABC Ltda"
customer.customerId     # => 127
customer.isActive       # => true
customer.address        # => Address object or nil

# List with filters
customers = Conexa::Customer.all(
  companyId: [3],
  isActive: true,
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

# Related data
Conexa::Customer.persons(127)    # List requesters
Conexa::Customer.contracts(127)  # List contracts
Conexa::Customer.charges(127)    # List charges
```

**Customer attributes:**
- `customerId` - ID
- `companyId` - Unit/company ID
- `name` - Full name
- `tradeName` - Trade name (optional)
- `hasLoginAccess` - Has portal access
- `isActive` - Active status
- `isBlocked` - Blocked status
- `isJuridicalPerson` - Is PJ (legal person)
- `isForeign` - Is foreigner
- `address` - Address object
- `legalPerson` - PJ data (cnpj, etc)
- `naturalPerson` - PF data (cpf, etc)
- `phones` - Array of phones
- `emailsMessage` - General emails
- `emailsFinancialMessages` - Financial emails
- `tagsId` - Tag IDs
- `createdAt` - Creation timestamp

---

### Contract

Manages recurring billing contracts.

```ruby
# Create contract
contract = Conexa::Contract.create(
  customerId: 127,
  planId: 5,
  startDate: '2024-01-01',
  paymentDay: 10,
  invoicingMethodId: 1
)

# Create with custom products (no plan)
contract = Conexa::Contract.create_with_products(
  customerId: 127,
  startDate: '2024-01-01',
  paymentDay: 10,
  items: [
    { productId: 100, quantity: 1, amount: 99.90 },
    { productId: 101, quantity: 2, amount: 50.00 }
  ]
)

# Find contract
contract = Conexa::Contract.find(456)
contract.status      # => "active"
contract.active?     # => true
contract.planId      # => 5
contract.paymentDay  # => 10

# List contracts
contracts = Conexa::Contract.all(
  customerId: [127],
  status: 'active'
)

# End/terminate contract
contract.end_contract(endDate: '2024-12-31', reason: 'Cliente solicitou')
# or
Conexa::Contract.end_contract(456, endDate: '2024-12-31')

# Update
contract.paymentDay = 15
contract.save
```

**Contract attributes:**
- `contractId` - ID
- `customerId` - Customer ID
- `planId` - Plan ID (optional)
- `status` - Status (active, ended, cancelled)
- `startDate` - Start date
- `endDate` - End date (if terminated)
- `paymentDay` - Day of month for billing (1-28)

**Methods:**
- `active?` - Check if active
- `ended?` - Check if ended/cancelled
- `end_contract(params)` - Terminate contract

---

### Charge

Manages invoices/boletos.

```ruby
# Find charge
charge = Conexa::Charge.find(789)
charge.status     # => "pending"
charge.amount     # => 199.90
charge.dueDate    # => "2024-02-10"
charge.pending?   # => true
charge.paid?      # => false

# List charges
charges = Conexa::Charge.all(
  customerId: [127],
  status: 'pending',
  dueDateFrom: '2024-01-01',
  dueDateTo: '2024-01-31'
)

# Settle (mark as paid)
charge.settle(paymentDate: '2024-02-05', paymentValue: 199.90)
# or
Conexa::Charge.settle(789, paymentDate: '2024-02-05')

# Get PIX QR Code
pix = charge.pix
pix.qrCode       # => "00020126..."
pix.qrCodeImage  # => Base64 image

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
- `chargeId` - ID
- `customerId` - Customer ID
- `status` - Status (pending, paid, overdue, cancelled)
- `amount` - Amount due
- `dueDate` - Due date

**Methods:**
- `pending?` / `paid?` / `overdue?` - Status checks
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
  customerId: 450,
  productId: 2521,
  quantity: 1,
  amount: 80.99,
  referenceDate: '2024-01-15',
  notes: 'Venda avulsa'
)

# Find sale
sale = Conexa::Sale.find(1234)
sale.status        # => "notBilled"
sale.amount        # => 80.99
sale.editable?     # => true (if notBilled)

# List sales
sales = Conexa::Sale.all(
  customerId: [450],
  status: 'notBilled',
  referenceDateFrom: '2024-01-01',
  referenceDateTo: '2024-01-31'
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
  contractId: [456],
  status: 'active'
)

# End recurring sale
rs.end_recurring_sale(endDate: '2024-12-31')
# or
Conexa::RecurringSale.end_recurring_sale(555, endDate: '2024-12-31')
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
plans = Conexa::Plan.all(companyId: [3])
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
products = Conexa::Product.all(companyId: [3])
```

**Note:** Products cannot be created/updated via API. Use Conexa dashboard.

---

### Bill

Read-only resource for financial bills (contas a pagar).

```ruby
# Find bill
bill = Conexa::Bill.find(321)

# List bills
bills = Conexa::Bill.all(companyId: [3])
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
suppliers = Conexa::Supplier.all(companyId: [3])

# Create supplier
supplier = Conexa::Supplier.create(
  companyId: 3,
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
  customerId: 127,
  token: 'card_token_from_gateway'
)
```

---

### Person

Manages requesters (solicitantes) for a customer. Limited API access.

```ruby
# Create person for customer
person = Conexa::Person.create(
  customerId: 127,
  name: 'Maria Solicitante',
  email: 'maria@empresa.com'
)

# Note: find/all not available directly - use Customer.persons(id)
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
  dueDateFrom: '2024-01-01',
  dueDateTo: '2024-01-31'
)

# Multiple IDs
Conexa::Customer.all(companyId: [1, 2, 3])

# Status filters
Conexa::Contract.all(status: 'active')
Conexa::Sale.all(status: 'notBilled')

# Combined
Conexa::Charge.all(
  customerId: [127],
  status: 'pending',
  dueDateFrom: '2024-01-01',
  page: 1,
  size: 100
)
```

---

## Model Methods Summary

| Resource | find | all | create | save | destroy | Special Methods |
|----------|------|-----|--------|------|---------|-----------------|
| Customer | ✅ | ✅ | ✅ | ✅ | ✅ | persons, contracts, charges |
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
