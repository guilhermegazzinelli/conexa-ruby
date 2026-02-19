# Conexa Ruby - LLM Reference

> Ruby client for the Conexa API - Brazilian billing and subscription management platform.

## Overview

Conexa is a Brazilian SaaS platform for **recurring billing**, **subscription management**, and **financial operations**. This gem provides a Ruby interface to their REST API v2.

**Key concepts:**
- **Auth** - Username/password authentication (JWT)
- **Customer** - Client (PF or PJ) who receives invoices
- **Contract** - Recurring billing agreement with a plan
- **Charge** - Individual invoice/boleto generated for payment
- **Sale** - One-time sale (not recurring)
- **RecurringSale** - Recurring sale item within a contract
- **Plan** - Pricing plan with products and periodicities
- **Product** - Billable item/service
- **InvoicingMethod** - Payment method configuration (boleto, PIX, credit card)
- **Person** - Requester (solicitante) linked to a customer
- **Bill** - Financial bill (conta a pagar)
- **Supplier** - Supplier with PF/PJ data

## Installation

```ruby
# Gemfile
gem 'conexa', '~> 0.0.7'

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
# Correct - snake_case
Conexa::Customer.create(
  company_id: 3,
  legal_person: { cnpj: '99.557.155/0001-90' }
)

# Avoid - camelCase (works but not idiomatic)
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

### Auth

Authenticates with username/password and returns a JWT token. Does not require a pre-configured `api_token`.

```ruby
# Authenticate
auth = Conexa::Auth.login(username: 'admin', password: 'secret')
# or
auth = Conexa::Auth.authenticate(username: 'admin', password: 'secret')

auth.access_token  # => "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
auth.token_type    # => "Bearer"
auth.expires_in    # => 28800 (8 hours in seconds)
auth.user.id       # => 1
auth.user.type     # => "admin" or "employee"
auth.user.name     # => "Luke Skywalker"

# Use the token for subsequent requests
Conexa.configure { |c| c.api_token = auth.access_token }
```

**API endpoint:** `POST /auth`

**Request body:**
- `username` - Login username (admin login or employee email)
- `password` - Password

**Response attributes:**
- `user` - User object with `id`, `type`, `name`
- `token_type` - Always "Bearer"
- `access_token` - JWT token for subsequent requests
- `expires_in` - Token expiration in seconds (28800 = 8 hours)

**Errors:**
- `Conexa::ResponseError` - Invalid credentials (401), validation errors (400)

---

### Customer

Manages clients (pessoas fisicas ou juridicas).

```ruby
# Create customer (Pessoa Juridica)
customer = Conexa::Customer.create(
  company_id: 3,
  name: 'Empresa ABC Ltda',
  trade_name: 'ABC',
  field_of_activity: 'Tecnologia',
  notes: 'Cliente VIP',
  cell_number: '31999998888',
  phones: ['3133334444', '3144445555'],
  website: 'https://www.abc.com.br',
  has_login_access: true,
  login: 'empresa@abc.com.br',
  password: 'SecurePass123',
  legal_person: {
    cnpj: '99.557.155/0001-90',
    foundation_date: '2020-01-15',
    state_inscription: '123456789',
    municipal_inscription: '98765432'
  },
  address: {
    zip_code: '30130000',
    state: 'MG',
    city: 'Belo Horizonte',
    street: 'Av. Afonso Pena',
    number: '1000',
    neighborhood: 'Centro',
    additional_details: 'Sala 501'
  },
  emails_message: ['contato@abc.com.br'],
  emails_financial_messages: ['financeiro@abc.com.br'],
  default_due_day: 10,
  tax_deductions: {
    iss: 0, ir: 0, pis: 0, inss: 0, csll: 0, cofins: 0
  },
  extra_fields: [
    { id: 1, value: 'Valor 1' }
  ]
)

# Create customer (Pessoa Fisica)
customer = Conexa::Customer.create(
  company_id: 3,
  name: 'Joao Silva',
  natural_person: {
    cpf: '123.456.789-00',
    rg: '123456789',
    birth_date: '1990-05-15',
    issuing_authority: 'SSP/MG',
    profession: 'Desenvolvedor',
    marital_status: 'single'  # single, married, divorced, widowed, not informed
  }
)

# Create customer (Estrangeiro)
customer = Conexa::Customer.create(
  company_id: 3,
  name: 'John Smith',
  foreign: {
    document: 'ABC123456',
    birth_date: '1985-03-20',
    profession: 'Engineer'
  }
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

# Sub-resources
Conexa::Customer.persons(127)    # List persons for customer
Conexa::Customer.contracts(127)  # List contracts for customer
Conexa::Customer.charges(127)    # List charges for customer
```

**API endpoints:** `POST /customer`, `GET /customer/:id`, `PATCH /customer/:id`, `DELETE /customer/:id`, `GET /customers`

**Create/update attributes:**
- `company_id` - Unit/company ID (required on create)
- `name` - Full name (required on create)
- `trade_name` - Trade name (optional)
- `pronunciation` - Name pronunciation (optional)
- `field_of_activity` - Field of activity
- `notes` - General notes
- `cell_number` - Cell phone number
- `phones` - Array of phone numbers
- `website` - Website URL
- `has_login_access` - Has portal access (boolean)
- `login` - Login email (when has_login_access is true)
- `password` - Login password (when has_login_access is true)
- `legal_person` - PJ data: `cnpj`, `foundation_date`, `state_inscription`, `municipal_inscription`
- `natural_person` - PF data: `cpf`, `rg`, `birth_date`, `issuing_authority`, `profession`, `marital_status`
- `foreign` - Foreign data: `document`, `birth_date`, `profession`
- `address` - Address: `zip_code`, `state`, `city`, `street`, `number`, `neighborhood`, `additional_details`
- `mailing_address` - Mailing address (same structure as address)
- `emails_message` - Array of general emails
- `emails_financial_messages` - Array of financial emails
- `tags_id` - Array of tag IDs
- `default_due_day` - Default due day for charges
- `tax_deductions` - Tax deductions: `iss`, `ir`, `pis`, `inss`, `csll`, `cofins`
- `extra_fields` - Array of `{ id, value }` for custom fields
- `automatically_issue_nfse` - Auto-generate NFSe (boolean)
- `notes_nfse` - NFSe notes
- `extension_numbers` - Extension numbers

**Read-only attributes:**
- `customer_id` - ID
- `is_active` - Active status
- `is_blocked` - Blocked status
- `is_juridical_person` - Is PJ (legal person)
- `is_foreign` - Is foreigner
- `created_at` - Creation timestamp

---

### Contract

Manages recurring billing contracts.

```ruby
# Create contract with plan
contract = Conexa::Contract.create(
  customer_id: 127,
  plan_id: 5,
  start_date: '2024-01-01',
  due_day: 10,
  payment_frequency: 'monthly',
  amount: 500.00,
  seller_id: 1,
  contract_summary: 'Contrato mensal',
  notes: 'Observacoes',
  membership_fee: 100.00,
  generate_sales: true,
  prorata_type: 'proportional',
  nfse_description: 'Servicos de coworking',
  refund: {
    amount: 1000.00,
    date_limit: '2025-01-01',
    is_to_generate_refund_billet: false
  },
  complementary_services: [
    { product_or_service_id: 100, quantity: 1, amount: 50.00, notes: 'Servico extra' }
  ],
  service_correspondence_quotas: {
    limited: true,
    messages_limit: 100,
    price_additional_message: 2.50
  }
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
contract.active?      # => true
contract.ended?       # => false

# List contracts
contracts = Conexa::Contract.all(
  customer_id: [127],
  status: 'active'
)

# End/terminate contract
contract.end_contract(date: '2024-12-31', reason_id: 1, unlink_customer: false)
# or
Conexa::Contract.end_contract(456, date: '2024-12-31')

# Update
contract.due_day = 15
contract.save

# Delete
contract.destroy
```

**API endpoints:** `POST /contract`, `GET /contract/:id`, `PATCH /contract/:id`, `DELETE /contract/:id`, `PATCH /contract/end/:id`, `GET /contracts`

**Create attributes:**
- `customer_id` - Customer ID (required)
- `plan_id` - Plan ID (optional, alternative to items)
- `payment_frequency` - monthly, bimonthly, quarterly, semester, yearly
- `start_date` - Start date
- `end_date` - End date (optional)
- `due_day` - Day of month for billing (1-28)
- `fidelity_date` - Fidelity end date
- `amount` - Contract value
- `discount_value` - Discount value
- `seller_id` - Seller user ID
- `contract_summary` - Summary text
- `notes` - Notes
- `membership_fee` - Membership fee
- `generate_sales` - Auto-generate sales (boolean)
- `prorata_type` - Prorata type
- `nfse_description` - NFSe description
- `discount_on_rooms` - Room discount percentage
- `discount_on_workstation` - Workstation discount percentage
- `private_space_id` - Private space ID
- `is_sms_enabled` - SMS notifications (boolean)
- `refund` - Refund config: `amount`, `date_limit`, `is_to_generate_refund_billet`
- `complementary_services` - Array of: `product_or_service_id`, `quantity`, `amount`, `notes`
- `service_correspondence_quotas` - Quotas: `limited`, `messages_limit`, `price_additional_message`

**End contract params:**
- `date` - End date
- `reason_id` - Reason ID
- `unlink_customer` - Unlink customer (boolean)

**Read-only attributes:**
- `contract_id` - ID
- `status` - active, ended, cancelled

**Helper methods:**
- `active?` - Check if active
- `ended?` - Check if ended or cancelled

---

### Charge

Manages invoices/boletos. Charges are created from sales.

```ruby
# Create charge from sales
charge = Conexa::Charge.create(
  sales_ids: [1234, 1235],
  invoicing_method_id: 1,
  due_date: '2024-02-10',
  notes: 'Cobranca mensal'
)

# Find charge
charge = Conexa::Charge.find(789)
charge.status      # => "pending"
charge.amount      # => 199.90
charge.due_date    # => "2024-02-10"
charge.paid?       # => false
charge.pending?    # => true
charge.overdue?    # => false

# List charges
charges = Conexa::Charge.all(
  customer_id: [127],
  status: 'pending',
  due_date_from: '2024-01-01',
  due_date_to: '2024-01-31'
)

# Settle (mark as paid)
charge.settle(
  settlement_date: '2024-02-05',
  paid_amount: 199.90,
  account_id: 1,
  send_email: true,
  receiving_method: { id: 1, installments_quantity: 1 }
)
# or
Conexa::Charge.settle(789, settlement_date: '2024-02-05')

# Get PIX QR Code
pix = charge.pix
# or
pix = Conexa::Charge.pix(789)

# Send email notification
charge.send_email
# or
Conexa::Charge.send_email(789)

# Cancel charge
charge.cancel
# or
Conexa::Charge.cancel(789)
```

**API endpoints:** `POST /charge`, `GET /charge/:id`, `GET /charges`, `PATCH /charge/settle/:id`, `GET /charge/pix/:id`

**Create attributes:**
- `sales_ids` - Array of sale IDs to include in charge
- `invoicing_method_id` - Payment method ID
- `due_date` - Due date
- `notes` - Notes

**Settle attributes:**
- `settlement_date` - Payment date
- `paid_amount` - Amount paid
- `account_id` - Bank account ID
- `send_email` - Send confirmation email (boolean)
- `receiving_method` - Payment method: `id`, `installments_quantity`

**Read-only attributes:**
- `charge_id` - ID
- `customer_id` - Customer ID
- `status` - pending, paid, overdue, cancelled
- `amount` - Amount due
- `due_date` - Due date
- `paid_at` - Payment date

**Helper methods:**
- `paid?` - Check if paid
- `pending?` - Check if pending
- `overdue?` - Check if overdue

**Special methods:**
- `settle(params)` / `Charge.settle(id, params)` - Mark as paid
- `pix` / `Charge.pix(id)` - Get PIX payment data
- `send_email` / `Charge.send_email(id)` - Send notification
- `cancel` / `Charge.cancel(id)` - Cancel charge

---

### Sale

Manages one-time sales.

```ruby
# Create sale
sale = Conexa::Sale.create(
  customer_id: 450,
  product_id: 2521,
  requester_id: 10,
  seller_id: 1,
  quantity: 1,
  amount: 80.99,
  reference_date: '2024-01-15',
  notes: 'Venda avulsa'
)

# Find sale
sale = Conexa::Sale.find(1234)
sale.status      # => "notBilled"
sale.amount      # => 80.99
sale.editable?   # => true
sale.billed?     # => false
sale.paid?       # => false

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

**API endpoints:** `POST /sale`, `GET /sale/:id`, `PATCH /sale/:id`, `DELETE /sale/:id`, `GET /sales`

**Create/update attributes:**
- `customer_id` - Customer ID (required)
- `product_id` - Product ID (required)
- `requester_id` - Requester (person) ID
- `seller_id` - Seller (user) ID
- `quantity` - Quantity (required)
- `amount` - Amount (required)
- `reference_date` - Reference date
- `notes` - Notes

**Read-only attributes:**
- `sale_id` - ID
- `status` - Status string
- `original_amount` - Original amount before discount
- `discount_value` - Discount value
- `created_at` - Creation timestamp
- `updated_at` - Update timestamp

**Sale statuses:**
- `notBilled` - Not yet billed (editable)
- `billed` - Included in a charge
- `paid` - Paid
- `cancelled` - Cancelled
- `deductedFromQuota` - Deducted from quota
- `billedCancelled` - Billing cancelled
- `billedNegociated` - Negotiated
- `partiallyPaid` - Partially paid

**Helper methods:**
- `editable?` - Check if status is notBilled
- `billed?` - Check if billed
- `paid?` - Check if paid

---

### RecurringSale

Manages recurring items within contracts.

```ruby
# Create recurring sale
rs = Conexa::RecurringSale.create(
  customer_id: 127,
  type: 'product',           # 'package' or 'product'
  reference_id: 100,         # product or package ID
  requester_id: 10,
  seller_id: 1,
  is_repeat: true,
  occurrence_quantity: 12,
  frequency: 'monthly',
  start_date: '2024-01-01',
  quantity: 1,
  amount: 99.90,
  notes: 'Venda recorrente'
)

# Find recurring sale
rs = Conexa::RecurringSale.find(555)

# List recurring sales
recurring = Conexa::RecurringSale.all(
  contract_id: [456],
  status: 'active'
)

# Update
rs.amount = 109.90
rs.save

# End recurring sale
rs.end_recurring_sale(date: '2024-12-31')
# or
Conexa::RecurringSale.end_recurring_sale(555, date: '2024-12-31')

# Delete
rs.destroy
```

**API endpoints:** `POST /recurringSale`, `GET /recurringSale/:id`, `PATCH /recurringSale/:id`, `DELETE /recurringSale/:id`, `PATCH /recurringSale/end/:id`, `GET /recurringSales`

**Create attributes:**
- `customer_id` - Customer ID
- `type` - 'package' or 'product'
- `reference_id` - Product or package ID
- `requester_id` - Requester ID
- `seller_id` - Seller ID
- `is_repeat` - Is repeating (boolean)
- `occurrence_quantity` - Number of occurrences
- `frequency` - Frequency string
- `start_date` - Start date
- `last_adjustment_date` - Last price adjustment date
- `quantity` - Quantity
- `amount` - Amount
- `notes` - Notes
- `is_discount_previous_reservations` - Discount previous reservations (boolean)
- `is_calculate_pro_rata` - Calculate pro rata (boolean)

**Update attributes:**
- `requester_id`, `amount`, `quantity`, `last_adjustment_date`, `notes`

---

### Plan

Pricing plans with products and periodicities.

```ruby
# Create plan
plan = Conexa::Plan.create(
  company_id: 1,
  name: 'Plano Basico',
  service_category_id: 1,
  cost_center_id: 10,
  description: 'Plano com todos os recursos',
  membership_fee: 200.00,
  refund_value: 1500.00,
  fidelity_months: 12,
  due_day: 10,
  nfse_description: 'Servicos de coworking',
  receipt_description: 'Recibo mensal',
  discount_on_rooms: 15.5,
  discount_on_workstation: 10.0,
  is_sms_enabled: true,
  payment_periodicities: [
    { periodicity: 'monthly', amount: 500.00 },
    { periodicity: 'quarterly', amount: 1400.00 },
    { periodicity: 'yearly', amount: 5000.00 }
  ],
  product_quotas: [
    { product_id: 100, quantity: 10 },
    { product_id: 101, quantity: 5 }
  ],
  service_correspondence_quotas: {
    limited: true,
    messages_limit: 100,
    price_additional_message: 2.50
  },
  booking_models: [
    { id: 1, stations: 2 }
  ],
  private_space_ids: [10, 11, 12],
  hour_quotas: [
    { hours: 10, periodicity: 'daily', space_id: 5 },
    { hours: 40, periodicity: 'weekly', group_id: 3 }
  ]
)

# Find plan
plan = Conexa::Plan.find(5)
plan.name   # => "Plano Basico"

# List plans
plans = Conexa::Plan.all(company_id: [3])

# Delete
plan.destroy
```

**API endpoints:** `POST /plan`, `GET /plan/:id`, `PATCH /plan/:id`, `DELETE /plan/:id`, `GET /plans`

**Note:** `save` (update) raises `NoMethodError` in the gem. Use `Conexa::Request` directly if needed.

**Create attributes:**
- `company_id` - Company ID (required)
- `name` - Plan name (required, must be unique)
- `service_category_id` - Service category ID (required)
- `cost_center_id` - Cost center ID
- `description` - Description
- `membership_fee` - Membership fee
- `refund_value` - Refund value
- `fidelity_months` - Fidelity period in months
- `due_day` - Default due day
- `nfse_description` - NFSe description
- `receipt_description` - Receipt description
- `discount_on_rooms` - Room discount percentage
- `discount_on_workstation` - Workstation discount percentage
- `is_sms_enabled` - SMS enabled (boolean)
- `payment_periodicities` - Array of: `periodicity` (monthly, bimonthly, quarterly, semester, yearly), `amount`
- `product_quotas` - Array of: `product_id`, `quantity`
- `service_correspondence_quotas` - `limited`, `messages_limit`, `price_additional_message`
- `booking_models` - Array of: `id`, `stations`
- `private_space_ids` - Array of space IDs
- `hour_quotas` - Array of: `hours`, `periodicity`, `group_id`, `space_id`

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

**API endpoints:** `GET /product/:id`, `GET /products`

**Note:** Products cannot be created/updated via this gem. `save` raises `NoMethodError`.

---

### InvoicingMethod

Manages payment method configurations (boleto, PIX, credit card, etc.).

```ruby
# Find invoicing method
method = Conexa::InvoicingMethod.find(1)
method.invoicing_method_id  # => 1

# List invoicing methods
methods = Conexa::InvoicingMethod.all

# Create
method = Conexa::InvoicingMethod.create(
  name: 'Boleto Bancario'
)

# Update
method.save

# Delete
method.destroy
```

**API endpoints:** `GET /invoicingMethod/:id`, `GET /invoicingMethods`, `POST /invoicingMethod`, `PATCH /invoicingMethod/:id`, `DELETE /invoicingMethod/:id`

---

### Bill

Financial bills (contas a pagar).

```ruby
# Create bill
bill = Conexa::Bill.create(
  company_id: 1,
  due_date: '2024-03-15',
  amount: 500.00,
  subcategory_id: 1,
  supplier_id: 50,
  description: 'Aluguel escritorio',
  account_id: 1,
  document_date: '2024-03-01',
  competence_date: '2024-03-01',
  document_number: 'NF-001',
  digitable_line: '23793.38128 60000.000003 00000.000400 1 84340000050000',
  cost_centers: [
    { id: 1, percentage: 100 }
  ],
  cac: { is_included: true, percentage: 5.0 }
)

# Find bill
bill = Conexa::Bill.find(321)

# List bills
bills = Conexa::Bill.all(company_id: [3])
```

**API endpoints:** `POST /bill`, `GET /bill/:id`, `GET /bills`

**Note:** `save` (update) raises `NoMethodError` in the gem.

**Create attributes:**
- `company_id` - Company ID
- `due_date` - Due date
- `amount` - Amount
- `subcategory_id` - Subcategory ID
- `supplier_id` - Supplier ID
- `description` - Description
- `account_id` - Bank account ID
- `document_date` - Document date
- `competence_date` - Competence date
- `document_number` - Document number
- `digitable_line` - Barcode digitable line
- `cost_centers` - Array of: `id`, `percentage`
- `cac` - CAC config: `is_included`, `percentage`

---

### Company

Manages units/companies within the account.

```ruby
# Find company
company = Conexa::Company.find(3)

# List companies
companies = Conexa::Company.all
```

**API endpoints:** `GET /company/:id`, `GET /companies`

---

### Supplier

Manages suppliers (fornecedores) with PF/PJ data.

```ruby
# Create supplier (PJ)
supplier = Conexa::Supplier.create(
  name: 'Fornecedor XYZ Ltda',
  field_of_activity: 'Servicos',
  notes: 'Fornecedor principal',
  cell_number: '31999998888',
  phones: ['3133334444'],
  emails: ['contato@xyz.com.br'],
  website: 'https://www.xyz.com.br',
  contact_person_names: ['Joao', 'Maria'],
  legal_person: {
    legal_name: 'Fornecedor XYZ Servicos Ltda',
    cnpj: '12.345.678/0001-90',
    state_inscription: '123456789',
    municipal_inscription: '98765432'
  },
  address: {
    zip_code: '30130000',
    state: 'MG',
    city: 'Belo Horizonte',
    street: 'Rua da Bahia',
    number: '500',
    neighborhood: 'Centro',
    additional_details: 'Sala 10'
  }
)

# Create supplier (PF)
supplier = Conexa::Supplier.create(
  name: 'Joao Fornecedor',
  natural_person: {
    cpf: '123.456.789-00',
    rg: '123456789',
    issuing_authority: 'SSP/MG'
  }
)

# Find supplier
supplier = Conexa::Supplier.find(50)

# List suppliers
suppliers = Conexa::Supplier.all(company_id: [3])

# Update
supplier.name = 'Novo Nome'
supplier.save

# Delete
supplier.destroy
```

**API endpoints:** `POST /supplier`, `GET /supplier/:id`, `PATCH /supplier/:id`, `DELETE /supplier/:id`, `GET /supplier` (list)

**Create attributes:**
- `name` - Supplier name (required)
- `field_of_activity` - Field of activity
- `notes` - Notes
- `cell_number` - Cell phone
- `phones` - Array of phones
- `emails` - Array of emails
- `website` - Website URL
- `contact_person_names` - Array of contact names
- `legal_person` - PJ data: `legal_name`, `cnpj`, `state_inscription`, `municipal_inscription`
- `natural_person` - PF data: `cpf`, `rg`, `issuing_authority`
- `address` - Address: `zip_code`, `state`, `city`, `street`, `number`, `neighborhood`, `additional_details`

---

### CreditCard

Manages customer credit cards.

```ruby
# Create credit card
card = Conexa::CreditCard.create(
  customer_id: 127,
  number: '4111111111111111',
  name: 'JOAO DA SILVA',
  expiration_date: '12/2026',
  cvc: '123',
  brand: 'visa',
  default: true,
  enable_recurring: true
)

# Find credit card
card = Conexa::CreditCard.find(99)

# Update
card.default = true
card.save

# Delete
card.destroy
```

**API endpoints:** `POST /creditCard`, `GET /creditCard/:id`, `PATCH /creditCard/:id`, `DELETE /creditCard/:id`

**Note:** `all` (listing) is not available for credit cards.

**Create attributes:**
- `customer_id` - Customer ID (required)
- `number` - Card number
- `name` - Cardholder name
- `expiration_date` - Expiration date (MM/YYYY)
- `cvc` - CVC code
- `brand` - Card brand
- `default` - Set as default (boolean)
- `enable_recurring` - Enable for recurring charges (boolean)

---

### Person

Manages requesters (solicitantes) linked to a customer. The API supports full CRUD.

```ruby
# Create person for customer
person = Conexa::Person.create(
  customer_id: 127,
  name: 'Maria Solicitante',
  nationality: 'Brasileira',
  place_of_birth: 'Belo Horizonte',
  marital_status: 'single',
  is_foreign: false,
  is_company_partner: true,
  is_guarantor: false,
  cpf: '123.456.789-00',
  rg: '123456789',
  issuing_authority: 'SSP/MG',
  birth_date: '1990-05-15',
  cell_number: '31999998888',
  phones: ['3133334444'],
  emails: ['maria@empresa.com'],
  sex: 'female',
  job_title: 'Gerente',
  profession: 'Administradora',
  resume: 'Profissional experiente',
  notes: 'Contato principal',
  address: {
    zip_code: '30130000',
    state: 'MG',
    city: 'Belo Horizonte',
    street: 'Av. Afonso Pena',
    number: '1000',
    neighborhood: 'Centro',
    additional_details: 'Sala 501'
  },
  devices: [
    { nickname: 'Notebook', mac_address: 'AA:BB:CC:DD:EE:FF' }
  ],
  has_login_access: true,
  login: 'maria@empresa.com',
  password: 'SecurePass123',
  permissions: ['finance', 'orders', 'rooms'],
  can_receive_mail: true,
  color: '#FF5733',
  url_linkedin: 'https://linkedin.com/in/maria',
  url_instagram: '@maria',
  url_facebook: 'maria.fb',
  url_twitter: '@maria'
)

# Update
person.name = 'Maria Silva'
person.save

# Delete
person.destroy
```

**API endpoints:** `POST /person`, `GET /person/:id`, `PATCH /person/:id`, `DELETE /person/:id`, `GET /persons`

**Note:** In the gem, `find`, `all`, and `find_by` raise `NoMethodError`. Use `Conexa::Request` directly if you need to retrieve or list persons.

**Create/update attributes:**
- `customer_id` - Customer ID (required)
- `name` - Full name (required)
- `nationality` - Nationality
- `place_of_birth` - Place of birth
- `marital_status` - Marital status
- `is_foreign` - Is foreigner (boolean)
- `foreign_data` - Foreign data object
- `is_company_partner` - Is company partner (boolean)
- `is_guarantor` - Is guarantor (boolean)
- `cpf` - CPF number
- `rg` - RG number
- `issuing_authority` - RG issuing authority
- `birth_date` - Birth date
- `cell_number` - Cell phone
- `phones` - Array of phones
- `emails` - Array of emails
- `sex` - Gender (male, female)
- `job_title` - Job title
- `profession` - Profession
- `resume` - Resume/bio
- `notes` - Notes
- `address` - Address object
- `devices` - Array of: `nickname`, `mac_address`
- `has_login_access` - Has portal access (boolean)
- `login` - Login email
- `password` - Login password
- `permissions` - Array of: finance, orders, rooms, shared_spaces, assistance, correspondences, printing
- `access_id` - Access ID
- `can_receive_mail` - Can receive mail (boolean)
- `color` - Color code
- `print_fee_id` - Print fee ID
- `extension_numbers` - Extension numbers
- `url_linkedin`, `url_instagram`, `url_facebook`, `url_twitter` - Social URLs

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
- `Conexa::ValidationError` - Validation failed (response without `message` key)
- `Conexa::ResponseError` - API error with `message` key (400, 401, 422, 500)
- `Conexa::ConnectionError` - Network error
- `Conexa::RequestError` - Invalid request parameters (e.g., nil ID)
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

### Rate Limiting

The API enforces a limit of 100 requests per minute. Response headers:
- `X-Rate-Limit-Limit` - Maximum requests per minute
- `X-Rate-Limit-Remaining` - Remaining requests
- `X-Rate-Limit-Reset` - Seconds until limit resets

---

## Model Methods Summary

| Resource | find | all | create | save | destroy | Special Methods |
|----------|------|-----|--------|------|---------|-----------------|
| Auth | - | - | - | - | - | login, authenticate |
| Customer | yes | yes | yes | yes | yes | persons, contracts, charges |
| Contract | yes | yes | yes | yes | yes | end_contract, create_with_products |
| Charge | yes | yes | yes | - | - | settle, pix, cancel, send_email |
| Sale | yes | yes | yes | yes | yes | billed?, paid?, editable? |
| RecurringSale | yes | yes | yes | yes | yes | end_recurring_sale |
| Plan | yes | yes | yes | - | yes | - |
| Product | yes | yes | - | - | - | - |
| InvoicingMethod | yes | yes | yes | yes | yes | - |
| Bill | yes | yes | yes | - | - | - |
| Company | yes | yes | yes | yes | yes | - |
| Supplier | yes | yes | yes | yes | yes | - |
| CreditCard | yes | - | yes | yes | yes | - |
| Person | - | - | yes | yes | yes | - |

**Legend:** `yes` = available, `-` = not available (raises NoMethodError or not implemented)

---

## Version History

- **v0.0.7** - Add Auth resource, fix Auth.login, add test suite with VCR
- **v0.0.6** - Fix nil guard in camelize_hash, fix Result#empty? delegation
- **v0.0.5** - Initial public release

## Links

- **RubyGems:** https://rubygems.org/gems/conexa
- **GitHub:** https://github.com/guilhermegazzinelli/conexa-ruby
- **Conexa API Docs:** https://documenter.getpostman.com/view/25182821/2s93RZMpcB
