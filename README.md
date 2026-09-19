# BeGateway

Ruby client for the BeGateway payment platform API. It sends gateway transactions, creates checkout payment pages and verifies payment notifications.

## Installation

Add this line to your application's Gemfile:

    gem 'be_gateway'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install be_gateway

## Usage

### Intialization client

``` ruby
client = BeGateway::Client.new({
  shop_id: 'YOUR SHOP ID',
  secret_key: 'YOUR SHOP SECRET KEY',
  url: 'YOUR GATEWAY URL'
})
```

### Availibale actions:
* authorization
* authorize (*DEPRECATED*)
* capture
* void
* payment
* refund
* credit
* checkup
* tokenization
* payout
* fraud_advice
* p2p
* verify_p2p

**Pay attention** that client add main **'request'** section automatically, and you don't need to describe it

### Transaction Authorization example

``` ruby
response = client.authorization({
  amount: 100,
  currency: 'USD',
  description: 'Test transaction',
  tracking_id: 'tracking_id_000',
  billing_address: {
    first_name: 'John',
    last_name: 'Doe',
    country: 'US',
    city: 'Denver',
    state: 'CO',
    zip: '96002',
    address: '1st Street'
  },

  credit_card: {
    number: '4200000000000000',
    verification_value: '123',
    holder: 'John Doe',
    exp_month: '05',
    exp_year: '2020',
  },

  customer: {
    ip: '127.0.0.1',
    email: 'john@example.com'
  }
})

response.transaction.id # => returns id of processed transaciton
response.transaction.status # => returns status of processed transaciton

response.authorization.auth_code
response.authorization.rrn
```

### Transaction Payment

``` ruby
response = client.payment(params)
```
Where `params` have same structure as **Authorization**

### Transaction Checkup
This transaction allow you to check transaction via **beProtected** system.
``` ruby
response = client.checkup(params)
```
Where `params` have same structure as **Authorization**

### Transaction Refund example

``` ruby
response = client.refund({
  parent_uid:  'UID of original Payment or Capture transactions',
  amount:      'Amount of refund',
  reason:      'Reason of refund. Ex "Client request"'
})

response.transaction.uid    # => returns uid of processed transaciton
response.transaction.status # => returns status of processed transaciton
```

### Transaction Capture/Void

``` ruby
response = client.capture(params)
response = client.void(params)
```
Where `params` have same structure as **Refund**

### Transaction Credit example

``` ruby
response = client.credit({
  amount: 100,
  currency: "USD",
  description: "Test transaction",
  tracking_id: "tracking_id_000",
  credit_card: {
    token: "Token from successful Payment/Authorization transaction"
  }
})

response.transaction.uid    # => returns uid of processed transaciton
response.transaction.status # => returns status of processed transaciton
```

### Query Request example

``` ruby
response = client.query(id: transaction_id)

# or you can get transaction by tracking_id

response = client.query(tracking_id: 'your tracking id')

response.transaction.id # => returns id of processed transaciton
response.transaction.status # => returns status of processed transaciton
```

### Verify P2p

``` ruby
response = client.verify_p2p({
  amount: 100,
  currency: "USD",
  tracking_id: "tracking_id_000",
  credit_card: {
    number: "4012001037141112"
  },
  recipient_card: {
    number: "4200000000000000"
  },
  test: true
})

response.successful?  # => returns true or false
response.error?       # => returns true or false
response.message      # => returns response message
response.required_fields # => returns array of additional required fields for credit_card and recipient_card
response.required_fields["credit_card"]    # => returns required fields for credit_card
response.required_fields["recipient_card"] # => returns required fields for recipient_card. For example: ["holder"]
response.commission  # => returns commission. Example: { "minimum" => 0.7, "percent" => 1.5, "currency":"USD" }
response.commission["minimum"] # => 0.7
response.error_code   # => returns error code or nil
response.errors       # => returns array of errors fields or nil
response.errors["amount"] # => ["must be an integer"]
response.errors["recipient_card"]  # => { "number" => ["is not a card number"] }
```

### Checkout

``` ruby
checkout = BeGateway::Checkout.new({
  shop_id: 'YOUR SHOP ID',
  secret_key: 'YOUR SHOP SECRET KEY',
  url: 'https://checkout.bepaid.by'
})

response = checkout.get_token({
  transaction_type: 'payment',
  order: {
    amount: 4299, # 42.99 in minor units
    currency: 'BYN',
    description: 'Order 123',
    tracking_id: 'order-123'
  },
  settings: {
    notification_url: 'https://example.com/be_gateway/notifications',
    return_url: 'https://example.com/orders/123'
  },
  test: true
})

response['checkout']['redirect_url'] # => payment page to send the customer to
token = response['checkout']['token']

response = checkout.query(token)
```

### Notifications

The gateway posts notifications to `notification_url` with basic auth and a `Content-Signature` header, which signs the raw request body. Check both before trusting the body. The public key from the back office can be passed as is (base64 DER) or as PEM.

``` ruby
class BeGatewayNotificationsController < ApplicationController
  skip_forgery_protection

  def create
    signed = BeGateway::Webhook.valid_signature?(
      request.raw_post,
      request.headers['Content-Signature'],
      'YOUR SHOP PUBLIC KEY'
    )
    authorized = BeGateway::Webhook.valid_authorization?(
      request.authorization,
      shop_id: 'YOUR SHOP ID',
      secret_key: 'YOUR SHOP SECRET KEY'
    )
    return head :unauthorized unless signed && authorized

    head :ok
  end
end
```

The gateway retries until it gets 200. Before fulfilling an order, confirm the final status with `client.query(tracking_id: ...)`.

### APIv3

### Intialization client

``` ruby
client = BeGateway::Client.new({
   ...
   version: 3
})
```

### Response
```
response.status           # => returns http status code
response.successful?      # => returns true or false
response.failed?          # => returns true or false
response.body             # => returns response body
response.code             # => returns API v3 response code ('S.0000')
response.message          # => returns response message
response.friendly_message # => returns response friendly_message
response.errors           # => returns array of errors
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
