# BeGateway

TODO: Write a gem description

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
* authorize
* capture
* void
* payment
* refund
* credit

**Pay attention** that client add main **'request'** section automatically, and you don't need to describe it

### Transaction Authorization example

``` ruby
response = client.authorize({
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

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
