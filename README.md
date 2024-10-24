# Conexa Ruby Gem

Conexa Ruby library

## Documentation

- [Conexa Website](https://conexa.app/)
- [API Documentation](https://conexa.app/api-docs)
- [Conexa API Postman Collection](https://web.postman.co/workspace/8e1887b1-bef9-4e36-848f-2b6774a81022/collection/33452984-58f4d7ab-d280-4aac-8578-8366988ff7af)

## Getting Started

### Install

```shell
gem install conexa-ruby
```

Or add the following line to your `Gemfile`:

```ruby
gem 'conexa-ruby'
```

Then run `bundle install` from your shell.

### Configure Your API Key

You can set your API credentials in Ruby:

```ruby
Conexa.configure do |config|
  config.api_token = ENV['API_TOKEN']
  config.api_host  = ENV['API_HOST']
end
```

Ensure that you have set the environment variables `API_TOKEN` and `API_HOST` with your Conexa API token and host URL.

## Usage

After configuration, you can start using the gem to interact with Conexa API resources.

### Available Resources

- `Bill`
- `Charge`
- `Contract`
- `Customer`
- `LegalPerson`
- `Person`
- `Plan`
- `Product`
- `RecurringSale`
- `Sale`

### Method Patterns

Each resource follows a consistent set of method patterns:

- `Conexa::<ResourceName>.new(params).create` - Create a new resource.
- `Conexa::<ResourceName>.find(id)` - Retrieve a resource by ID.
- `Conexa::<ResourceName>.find(filter_hash, page, size)` - Retrieve resources matching filters with pagination.
- `Conexa::<ResourceName>.destroy(id)` - Delete a resource by ID.
- `Conexa::<ResourceName>.find(id).destroy` - Find and delete a resource.

### Examples

#### Customers

##### Creating a Customer

```ruby
customer = Conexa::Customer.new(
  name:  'John Doe',
  email: 'john.doe@example.com',
  phone: '555-1234'
).create
```

##### Retrieving a Customer

```ruby
customer = Conexa::Customer.find(customer_id)
```

##### Updating a Customer

```ruby
customer = Conexa::Customer.find(customer_id)
customer.email = 'new.email@example.com'
customer.save
```

##### Deleting a Customer

```ruby
Conexa::Customer.destroy(customer_id)
```

Or:

```ruby
customer = Conexa::Customer.find(customer_id)
customer.destroy
```

##### Listing Customers

```ruby
customers = Conexa::Customer.find({ name: 'John Doe' }, 1, 20)
```

#### Bills

##### Creating a Bill

```ruby
bill = Conexa::Bill.new(
  customer_id: customer_id,
  amount:      1000,    # in cents
  due_date:    '2024-12-31'
).create
```

##### Retrieving a Bill

```ruby
bill = Conexa::Bill.find(bill_id)
```

##### Deleting a Bill

```ruby
Conexa::Bill.destroy(bill_id)
```

##### Listing Bills

```ruby
bills = Conexa::Bill.find({ status: 'pending' }, 1, 20)
```

#### Charges

##### Creating a Charge

```ruby
charge = Conexa::Charge.new(
  customer_id:          customer_id,
  amount:               1000,    # in cents
  payment_method:       'credit_card',
  card_number:          '4111111111111111',
  card_holder_name:     'John Doe',
  card_expiration_date: '12/25',
  card_cvv:             '123'
).create
```

##### Retrieving a Charge

```ruby
charge = Conexa::Charge.find(charge_id)
```

##### Deleting a Charge

```ruby
Conexa::Charge.destroy(charge_id)
```

##### Listing Charges

```ruby
charges = Conexa::Charge.find({ status: 'paid' }, 1, 20)
```

#### Plans

##### Creating a Plan

```ruby
plan = Conexa::Plan.new(
  name:          'Premium Plan',
  amount:        4990,   # in cents
  billing_cycle: 'monthly'
).create
```

##### Retrieving a Plan

```ruby
plan = Conexa::Plan.find(plan_id)
```

##### Deleting a Plan

```ruby
Conexa::Plan.destroy(plan_id)
```

##### Listing Plans

```ruby
plans = Conexa::Plan.find({}, 1, 20)
```

#### Contracts

##### Creating a Contract

```ruby
contract = Conexa::Contract.new(
  customer_id: customer_id,
  plan_id:     plan_id,
  start_date:  '2024-01-01',
  end_date:    '2024-12-31'
).create
```

##### Retrieving a Contract

```ruby
contract = Conexa::Contract.find(contract_id)
```

##### Deleting a Contract

```ruby
Conexa::Contract.destroy(contract_id)
```

##### Listing Contracts

```ruby
contracts = Conexa::Contract.find({ active: true }, 1, 20)
```

#### Products

##### Creating a Product

```ruby
product = Conexa::Product.new(
  name:        'Product Name',
  description: 'Product Description',
  price:       2990  # in cents
).create
```

##### Retrieving a Product

```ruby
product = Conexa::Product.find(product_id)
```

##### Deleting a Product

```ruby
Conexa::Product.destroy(product_id)
```

##### Listing Products

```ruby
products = Conexa::Product.find({ category: 'Electronics' }, 1, 20)
```

#### Sales

##### Creating a Sale

```ruby
sale = Conexa::Sale.new(
  customer_id: customer_id,
  product_id:  product_id,
  quantity:    2,
  total_amount: 5980  # in cents
).create
```

##### Retrieving a Sale

```ruby
sale = Conexa::Sale.find(sale_id)
```

##### Deleting a Sale

```ruby
Conexa::Sale.destroy(sale_id)
```

##### Listing Sales

```ruby
sales = Conexa::Sale.find({ date: '2024-01-01' }, 1, 20)
```

#### Recurring Sales

##### Creating a Recurring Sale

```ruby
recurring_sale = Conexa::RecurringSale.new(
  customer_id: customer_id,
  plan_id:     plan_id,
  start_date:  '2024-01-01'
).create
```

##### Retrieving a Recurring Sale

```ruby
recurring_sale = Conexa::RecurringSale.find(recurring_sale_id)
```

##### Deleting a Recurring Sale

```ruby
Conexa::RecurringSale.destroy(recurring_sale_id)
```

##### Listing Recurring Sales

```ruby
recurring_sales = Conexa::RecurringSale.find({ active: true }, 1, 20)
```

### Common Methods

Each resource provides common methods:

- `new(params).create` - Create a new record.
- `find(id)` - Retrieve a specific record by ID.
- `find(filter_hash, page, size)` - Retrieve records matching filters with pagination.
- `destroy(id)` - Delete a record by ID.
- `find(id).destroy` - Find and delete a record.

### Resource-Specific Operations

Some resources may offer additional methods specific to their functionality. Refer to the [Conexa API Documentation](https://conexa.app/api-docs) for detailed information.

## Validating Webhooks

To ensure that all received webhooks are sent by Conexa, you should validate the signature provided in the HTTP header `X-Signature`. You can validate it using the raw payload and the signature.

```ruby
valid = Conexa::Webhook.valid_request_signature?(raw_payload, signature)
```

### Rails Example

If you are using Rails, you can validate the webhook in your controller:

```ruby
class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def receive
    if valid_webhook?
      # Handle your code here
      # Webhook payload is in params
    else
      render_invalid_webhook_response
    end
  end

  private

  def valid_webhook?
    raw_payload = request.raw_post
    signature   = request.headers['X-Signature']
    Conexa::Webhook.valid_request_signature?(raw_payload, signature)
  end

  def render_invalid_webhook_response
    render json: { error: 'Invalid webhook' }, status: 400
  end
end
```

## Undocumented Features

This gem is stable but under continuous development. This README provides a quick overview of its main features.

You can explore the source code to see all [supported resources](lib/conexa/resources). We will continue to document and add support for all features listed in the [Conexa API Documentation](https://conexa.app/api-docs).

Feel free to contribute by sending pull requests.

## Support

If you have any problems or suggestions, please open an issue [here](https://github.com/guilhermegazzinelli/conexa-ruby/issues).

## License

This project is licensed under the [MIT License](LICENSE).

## Disclaimer

This gem is based on the Conexa API definitions available in the official [Postman collection](https://web.postman.co/workspace/8e1887b1-bef9-4e36-848f-2b6774a81022/collection/33452984-58f4d7ab-d280-4aac-8578-8366988ff7af). It currently supports authentication via API key only.

For more information about the Conexa API, visit the [official documentation](https://conexa.app/).
```

Feel free to copy and save this content as your `README.md` file.