require 'spec_helper'

describe BeGateway::Client do
  let(:params) do
    {
      shop_id: 1,
      secret_key: 'secret_key',
      url: 'https://gateway.ecomcharge.com'
    }
  end

  describe '.logger=' do
    let(:logger) { double('logger') }

    after { described_class.logger = nil }

    it "sets logger" do
      described_class.logger = logger

      expect(described_class.logger).to eq logger
    end
  end

  describe '#initialize' do
    context 'when absent required attribute' do
      before { params.delete(:shop_id) }

      it 'raises error for required attributes' do
        expect { described_class.new(params) }.to raise_error('key not found: :shop_id')
      end
    end

    context 'when passed headers' do
      let(:headers) { {'RequestID' => 'some-id'} }

      before { params[:headers] = headers }

      it 'sets up to passed_headers attribute reader' do
        client = described_class.new(params)
        expect(client.passed_headers).to eq headers
      end
    end
  end

  describe 'verify_p2p' do
    let(:client) { described_class.new(params) }
    let(:request_params) do
      {
        "amount"   => 100,
        "currency" => "USD",
        "credit_card"    => { "number" => "4012001037141112" },
        "recipient_card" => { "number" => "4200000000000000" },
        "test" => true
      }
    end
    let(:response_body) do
      {
        "status"  => "successful",
        "message" => "p2p is allowed",
        "required_fields" => {
          "credit_card"    => ["holder"],
          "recipient_card" => ["holder"]
        },
        "commission" => { "minimum" => 0.7, "percent" => 1.5, "currency":"USD" }
      }
    end
    let(:successful_response) { OpenStruct.new(status: 200, body: response_body) }

    before { allow_any_instance_of(Faraday::Connection).to receive(:post).and_return(successful_response) }

    it 'verifies p2p' do
      response = client.verify_p2p(request_params)

      expect(response.code).to eq 200
      expect(response.status).to eq('successful')
      expect(response.successful?).to be true
      expect(response.message).to eq('p2p is allowed')

      expect(response.required_fields['recipient_card']).to eq(['holder'])
      expect(response.commission['minimum']).to eq(0.7)
      expect(response.commission['percent']).to eq(1.5)

      expect(response.error?).to be false
      expect(response.error_code).to be nil
      expect(response.errors).to be nil
    end

    context 'when response is error' do
      let(:response_body) do
        {
          "message" => "Unprocessable entity",
          "errors" => {
            "amount"    => ["must be an integer"],
            "currency"  => ["is unknown ISO 4217 Alpha-3 code"],
            "credit_card"    => {"number" => ["is not a card number"]},
            "recipient_card" => {"number" => ["is not a card number"]}
          },
          "error_code" => "invalid_params"
        }
      end
      let(:error_response) { OpenStruct.new(status: 422, body: response_body) }

      before { allow_any_instance_of(Faraday::Connection).to receive(:post).and_return(error_response) }

      it "returns errors" do
        response = client.verify_p2p(request_params)

        expect(response.code).to eq 422
        expect(response.successful?).to be false
        expect(response.message).to eq('Unprocessable entity')

        expect(response.error?).to be true
        expect(response.error_code).to eq('invalid_params')
        expect(response.errors["amount"]).to eq(['must be an integer'])
        expect(response.errors["currency"]).to eq(['is unknown ISO 4217 Alpha-3 code'])

        expect(response.errors["credit_card"]["number"]).to eq(['is not a card number'])
        expect(response.errors["recipient_card"]["number"]).to eq(['is not a card number'])
      end
    end
  end

  describe 'credit card' do
    context 'v2' do
      let(:client) { described_class.new(params) }
      let(:request_params) do
        {
          'request' => {
            'number' => '4200000000000000',
            'holder' => 'John Smith',
            'exp_month' => '05',
            'exp_year' => '2019',
            'public_key' => 'public_key'
          }
        }
      end
      let(:response_body) do
        {
          'holder' => 'John Doe',
          'stamp' => 'a825df7faba8804619aef7a6d5a5821ec292fce04e3e43933ca33d0692df90b4',
          'brand' => 'visa',
          'last_4' => '0000',
          'first_1' => '4',
          'token' => '7ba647e7013b5cb9df39f17c375783aef81bc8c20f221b962becbd0686cc33af',
          'exp_month' => 1,
          'exp_year' => 2020
        }
      end
      let(:token) { '7ba647e7013b5cb9df39f17c375783aef81bc8c20f221b962becbd0686cc33af' }
      let(:successful_response) { OpenStruct.new(status: 200, body: response_body) }

      before { allow_any_instance_of(Faraday::Connection).to receive(:post).and_return(successful_response) }

      context 'create' do
        it 'returns credit_card information' do
          response = client.v2_create_card(request_params)
          expect(response.holder).to eq 'John Doe'
          expect(response.token).to eq '7ba647e7013b5cb9df39f17c375783aef81bc8c20f221b962becbd0686cc33af'
        end
      end

      context 'update by token' do
        before { allow_any_instance_of(Faraday::Connection).to receive(:put).and_return(successful_response) }

        it 'returns credit_card information' do
          response = client.v2_update_card_by_token(token, request_params)
          expect(response.holder).to eq 'John Doe'
          expect(response.token).to eq '7ba647e7013b5cb9df39f17c375783aef81bc8c20f221b962becbd0686cc33af'
        end
      end
    end
  end

  describe 'transactions' do
    let(:client) { described_class.new(params) }
    let(:request_params) do
      {
        'amount' => 100,
        'currency' => 'USD',
        'description' => 'Test transaction',
        'tracking_id' => 'your_uniq_number',
        'language' => 'en',
        'billing_address' => {
          'first_name' => 'John',
          'last_name' => 'Doe',
          'country' => 'US',
          'city' => 'Denver',
          'state' => 'CO',
          'zip' => '96002',
          'address' => '1st Street'
        },
        'credit_card' => {
          'number' => '4200000000000000',
          'verification_value' => '123',
          'holder' => 'John Doe',
          'exp_month' => '05',
          'exp_year' => '2020'
        },
        'customer' => {
          'ip' => '127.0.0.1',
          'email' => 'john@example.com'
        }
      }
    end

    context 'successful request' do
      let(:response_body) do
        {
          'transaction' => {
            'customer' => {
              'ip' => '127.0.0.1',
              'email' => 'john@example.com'
            },
            'credit_card' => {
              'holder' => 'John Doe',
              'stamp' => '3709786942408b77017a3aac8390d46d77d181e34554df527a71919a856d0f28',
              'token' => '40bd001563085fc35165329ea1ff5c5ecbdbbeef40bd001563085fc35165329e',
              'brand' => 'visa',
              'last_4' => '0000',
              'first_1' => '4',
              'exp_month' => 5,
              'exp_year' => 2015
            },
            'billing_address' => {
              'first_name' => 'John',
              'last_name' => 'Doe',
              'address' => '1st Street',
              'country' => 'US',
              'city' => 'Denver',
              'zip' => '96002',
              'state' => 'CO'
            },
            'authorization' => {
              'auth_code' => '654321',
              'bank_code' => '00',
              'rrn' => '999',
              'ref_id' => '777888',
              'message' => 'The operation was successfully processed.',
              'gateway_id' => 317,
              'billing_descriptor' => 'TEST GATEWAY BILLING DESCRIPTOR',
              'status' => 'successful'
            },
            'uid' => '4107-310b0da80b',
            'status' => 'successful',
            'message' => 'Successfully processed',
            'amount' => 100,
            'currency' => 'USD',
            'description' => 'Test order',
            'type' => 'authorization',
            'tracking_id' => 'your_uniq_number',
            'language' => 'en'
          }
        }
      end
      let(:successful_response) { OpenStruct.new(status: 200, body: response_body) }
      before { allow_any_instance_of(Faraday::Connection).to receive(:post).and_return(successful_response) }

      it 'returns transaction information' do
        response = client.authorize(request_params)

        expect(response.code).to eq 200
        expect(response.successful?).to eq(true)
        expect(response.transaction['currency']).to eq('USD')
        expect(response.transaction['amount']).to eq(100)
        expect(response.transaction['credit_card']['token']).to eq('40bd001563085fc35165329ea1ff5c5ecbdbbeef40bd001563085fc35165329e')
        expect(response.transaction['customer']['ip']).to eq('127.0.0.1')
        expect(response.transaction['billing_address']['first_name']).to eq('John')
        expect(response.transaction['uid']).to eq('4107-310b0da80b')
      end

      describe '#authorize' do
        it 'sends authorization request' do
          response = client.authorize(request_params)

          expect(response.transaction['type']).to eq('authorization')
          expect(response.transaction['authorization']['auth_code']).to eq('654321')
        end
      end

      describe '#authorization' do
        it 'sends authorization request' do
          response = client.authorization(request_params)

          expect(response.transaction['type']).to eq('authorization')
          expect(response.transaction['authorization']['auth_code']).to eq('654321')
        end
      end

      describe '#charge' do
        subject { client.charge(request_params) }

        it 'sends charge request' do
          expect_any_instance_of(Faraday::Connection)
            .to receive(:post)
            .with(%r{services/credit_cards/charges}, anything)

          subject

          expect(subject.transaction['type']).to eq('authorization')
          expect(subject.transaction['authorization']['auth_code']).to eq('654321')
        end
      end

      describe '#payment' do
        before do
          response_body['transaction'].tap do |hsh|
            hsh.delete('authorization')
            hsh['payment'] = {
              'auth_code' => '654321',
              'bank_code' => '00',
              'rrn' => '999',
              'ref_id' => '777888',
              'message' => 'The operation was successfully processed.',
              'gateway_id' => 317,
              'billing_descriptor' => 'TEST GATEWAY BILLING DESCRIPTOR',
              'status' => 'successful'
            }
            hsh['type'] = 'payment'
          end
        end

        it 'sends payment request' do
          response = client.payment(request_params)

          expect(response.transaction['type']).to eq('payment')
          expect(response.transaction['payment']['auth_code']).to eq('654321')
          expect(response.transaction['payment']['bank_code']).to eq('00')
        end
      end

      describe '#p2p' do
        context 'when response is successful' do
          before do
            response_body['transaction'].tap do |hsh|
              hsh.delete('authorization')
              hsh['p2p'] = {
                'auth_code' => '654321',
                'bank_code' => '00',
                'rrn' => '999',
                'ref_id' => '777888',
                'message' => 'The operation was successfully processed.',
                'gateway_id' => 317,
                'billing_descriptor' => 'TEST GATEWAY BILLING DESCRIPTOR',
                'status' => 'successful'
              }
              hsh['verify_p2p'] = {"status" => "successful", "message" => "p2p is allowed",
                "amount" => 100, "currency" => "USD", "bank_fee" => 1.05, "required_fields" => nil}
              hsh['type'] = 'p2p'
            end
          end

          it 'sends p2p request' do
            response = client.p2p(request_params)

            expect(response.transaction['type']).to eq('p2p')
            expect(response.transaction['p2p']['auth_code']).to eq('654321')
            expect(response.transaction['p2p']['bank_code']).to eq('00')

            expect(response.transaction.verify_p2p['bank_fee']).to eq(1.05)
          end
        end

        context 'when response is error' do
          let(:response_body) do
            {
              "response" => {
                "message" => "Number is invalid.",
                "errors"  => {
                  "recipient_card" => {"number" => ["is not a card number"]}
                }
              }
            }
          end
          let(:failed_response) { OpenStruct.new(status: 422, body: response_body) }

          before { allow_any_instance_of(Faraday::Connection).to receive(:post).and_return(failed_response) }

          it "returns errors" do
            response = client.p2p(request_params)

            expect(response.invalid?).to be true
            expect(response.status).to eq('error')
            expect(response.message).to eq('Number is invalid.')
            expect(response.errors["recipient_card"]["number"]).to eq(['is not a card number'])
          end
        end
      end

      describe '#tokenization' do
        let(:response_body) do
          {
            'transaction' => {
              'customer' => {
                'ip' => '127.0.0.1',
                'email' => 'john@example.com'
              },
              'credit_card' => {
                'token' => '40bd001563085fc35165329ea1ff5c5ecbdbbeef40bd001563085fc35165329e'
              },
              'billing_address' => {
                'first_name' => 'John',
                'last_name' => 'Doe',
                'address' => '1st Street',
                'country' => 'US',
                'city' => 'Denver',
                'zip' => '96002',
                'state' => 'CO'
              },
              'three_d_secure_verification' => {
                'eci' => '05',
                'pa_status' => 'Y',
                'xid' => 'Tk1CMjcyM0g0NFpZMlpWUzE2RlU=',
                'cavv' => 'AAACAQJwJTd4hwE5SHAlEwAAAAA=',
                'cavv_algorithm' => '2',
                'fail_reason' => nil,
                've_status' => 'Y',
                'message' => 'Authentication Successful',
                'status' => 'successful'
              },
              'uid' => '4107-310b0da80b',
              'status' => 'successful',
              'message' => 'Successfully processed',
              'amount' => 100,
              'currency' => 'USD',
              'description' => 'Test order',
              'type' => 'tokenization',
              'tracking_id' => 'your_uniq_number',
              'language' => 'en'
            }
          }
        end
        let(:successful_response) { OpenStruct.new(status: 200, body: response_body) }

        before { allow_any_instance_of(Faraday::Connection).to receive(:post).and_return(successful_response) }

        it 'returns transaction information among with credit card token' do
          response = client.tokenization(request_params)

          expect(response.transaction.uid).to eq('4107-310b0da80b')
          expect(response.transaction.credit_card['token'])
            .to eq('40bd001563085fc35165329ea1ff5c5ecbdbbeef40bd001563085fc35165329e')
        end
      end

      describe '#recipient_tokenization' do
        let(:request_params) do
          {
            'description' => 'Test recipient tokenization',
            'tracking_id' => 'your_uniq_number',
            'recipient_billing_address' => {
              'first_name' => 'John',
              'last_name' => 'Doe',
              'country' => 'US',
              'city' => 'Denver',
              'state' => 'CO',
              'zip' => '96002',
              'address' => '1st Street'
            },
            'recipient_card' => {
              'number' => '4200000000000000',
              'holder' => 'John Doe',
              'exp_month' => '05',
              'exp_year' => '2020'
            },
            'recipient' => {
              'ip' => '127.0.0.1',
              'email' => 'john@example.com'
            }
          }
        end
        let(:response_body) do
          {
            'transaction' => {
              'recipient' => {
                'ip' => '127.0.0.1',
                'email' => 'john@example.com'
              },
              'recipient_card' => {
                'token' => '40bd001563085fc35165329ea1ff5c5ecbdbbeef40bd001563085fc35165329e'
              },
              'recipient_billing_address' => {
                'first_name' => 'John',
                'last_name' => 'Doe',
                'address' => '1st Street',
                'country' => 'US',
                'city' => 'Denver',
                'zip' => '96002',
                'state' => 'CO'
              },
              'uid' => '4107-310b0da80b',
              'status' => 'successful',
              'message' => 'Successfully processed',
              'description' => 'Test recipient tokenization',
              'type' => 'recipient_tokenization',
              'tracking_id' => 'your_uniq_number'
            }
          }
        end
        let(:successful_response) { OpenStruct.new(status: 200, body: response_body) }

        before { allow_any_instance_of(Faraday::Connection).to receive(:post).and_return(successful_response) }

        it 'returns transaction information among with recipient card token' do
          response = client.recipient_tokenization(request_params)

          expect(response.transaction.uid).to eq('4107-310b0da80b')
          expect(response.transaction.recipient_card['token'])
            .to eq('40bd001563085fc35165329ea1ff5c5ecbdbbeef40bd001563085fc35165329e')
        end
      end

      context 'child' do
        %w(capture void refund).each do |tr_type|
          describe "##{tr_type}" do
            let(:request_params) do
              {}.tap do |hsh|
                hsh['parent_uid'] = '4107-310b0da80b'
                hsh['amount'] = 100
                hsh['reason'] = 'Client request' if tr_type == 'refund'
              end
            end
            before do
              response_body['transaction'].tap do |hsh|
                hsh.delete('authorization')
                hsh[tr_type.to_s] = {
                  'message' => 'The operation was successfully processed.',
                  'ref_id' => '8889999',
                  'gateway_id' => 152,
                  'status' => 'successful'
                }
                hsh['type'] = tr_type
              end
            end

            it "sends #{tr_type} request" do
              response = client.capture(request_params)

              expect(response.transaction['type']).to eq(tr_type)
              expect(response.transaction[tr_type]['ref_id']).to eq('8889999')
            end
          end
        end
      end

      context '#credit' do
        let(:request_params) do
          {
            'amount' => 100,
            'currency' => 'USD',
            'description' => 'Test transaction',
            'tracking_id' => 'tracking_id_000',
            'language' => 'en',
            'credit_card' => {
              'token' => '40bd001563085fc35165329ea1ff5c5ecbdbbeef40bd001563085fc35165329e'
            }
          }
        end

        before do
          response_body['transaction'].tap do |hsh|
            hsh.delete('authorization')
            hsh['credit'] = {
              'auth_code' => '654327',
              'bank_code' => '00',
              'rrn' => '934',
              'ref_id' => '777822',
              'message' => 'Credit was approved',
              'gateway_id' => 2124,
              'billing_descriptor' => 'TEST GATEWAY BILLING DESCRIPTOR',
              'status' => 'successful'
            }
            hsh['type'] = 'credit'
          end
        end

        it 'sends credit request' do
          response = client.credit(request_params)

          expect(response.transaction['type']).to eq('credit')
          expect(response.transaction['credit']['ref_id']).to eq('777822')
          expect(response.transaction['credit']['rrn']).to eq('934')
        end
      end

      context 'other' do
        context '#finalize_3ds' do
          before { allow_any_instance_of(Faraday::Connection).to receive(:post).and_return(successful_response) }
          let(:request_params) do
            {
              pa_res: 'some pa_res',
              md: 'some md',
              uid: '4107-310b0da80b'
            }
          end

          it 'sends finalize_3ds request' do
            response = client.finalize_3ds(request_params)

            expect(response.transaction['uid']).to eq('4107-310b0da80b')
            expect(response.transaction['status']).to eq('successful')
          end
        end

        context '#query' do
          before { allow_any_instance_of(Faraday::Connection).to receive(:get).and_return(successful_response) }
          let(:request_params) { { id: '4107-310b0da80b' } }

          it 'sends query request' do
            response = client.query(request_params)

            expect(response.transaction['currency']).to eq('USD')
            expect(response.transaction['amount']).to eq(100)
            expect(response.transaction['credit_card']['token']).to eq('40bd001563085fc35165329ea1ff5c5ecbdbbeef40bd001563085fc35165329e')
          end
        end

        context '#checkup' do
          before do
            response_body['transaction'].tap do |hsh|
              hsh['be_protected_verification'] = {
                'status' => 'successful',
                'white_black_list' => {
                  'email' => 'absent',
                  'ip' => 'absent',
                  'card_number' => 'white'
                },
                'rules' => {
                  '1_123_My Shop' => {
                    'more_100_eur' => { 'Transaction amount more than 100 AND Transaction currency is EUR' => 'passed' }
                  }
                }
              }
            end
          end

          it 'sends checkup request' do
            response = client.checkup(request_params)

            expect(response.transaction['be_protected_verification']['status']).to eq('successful')
            expect(response.transaction['be_protected_verification']['rules']['1_123_My Shop']).not_to be_empty
          end
        end

        context '#close_days' do
          context 'when gateway support close_days transaction' do
            let(:response_body) do
              {
                'transaction' => {
                  'status' => 'successful',
                  'success' => true,
                  'message' => 'Close day transaction successfully queued.'
                }
              }
            end

            let(:successful_response) { OpenStruct.new(status: 200, body: response_body) }
            before { allow_any_instance_of(Faraday::Connection).to receive(:post).and_return(successful_response) }

            it 'sends close_days request' do
              response = client.close_days(gateway_id: 1)

              expect(response.transaction.message).to eq('Close day transaction successfully queued.')
              expect(response.transaction.success).to eq(true)
              expect(response.transaction.status).to eq('successful')
            end
          end

          context 'when gateway does not support close_days transaction' do
            let(:response_body) do
              {
                'response' => {
                  'message' => 'Gateway does not support closing day transaction',
                  'errors' => { 'base' => 'Transaction is not supported' }
                }
              }
            end
            let(:failed_response) { OpenStruct.new(status: 422, body: response_body) }

            before { allow_any_instance_of(Faraday::Connection).to receive(:post).and_return(failed_response) }

            it 'gets unsupported action response' do
              response = client.close_days(gateway_id: 1)

              expect(response.message).to eq('Gateway does not support closing day transaction')
              expect(response.errors.base).to eq('Transaction is not supported')
            end
          end
        end

        context '#notification' do
          let(:body) {
            {
              "transaction" => {
                "uid" => "1-fc77f1e8f0",
                "status" => "successful",
                "amount" => nil,
                "currency" => nil,
                "description" => nil,
                "type" => "payment",
                "payment_method_type" => "credit_card",
                "tracking_id" => nil,
                "message" => nil,
                "test" => false,
                "created_at" => "2020-11-20T10: 42: 28.786Z",
                "updated_at" => "2020-11-20T10: 42: 28.786Z",
                "paid_at" => nil,
                "expired_at" => nil,
                "closed_at" => nil,
                "settled_at" => nil,
                "language" => "en",
                "redirect_url" => "http://127.0.0.1:9887/process/1-fc77f1e8f0",
                "credit_card" => {
                  "holder" => "Monty Hudson II",
                  "stamp" => "a825df7faba8804619aef7a6d5a5821ec292fce04e3e43933ca33d0692df90b4",
                  "brand" => "visa",
                  "last_4" => "0000",
                  "first_1" => "4",
                  "bin" => "420000",
                  "issuer_country" => "US",
                  "issuer_name" => "Demo Card Issuer",
                  "product" => nil,
                  "exp_month" => 12,
                  "exp_year" => 2020,
                  "token_provider" => nil,
                  "token" => nil
                },
                "receipt_url" => "default_domain/customer/transactions/1-fc77f1e8f0/06d2b42a8ee79a27c88a3dd0ef8cf12d3f1ebff2cd40d48523ea35d55d0539d4",
                "id" => "1-fc77f1e8f0",
                "customer" => nil,
                "billing_address" => nil
              }
            }
          }

          it 'accepts hashes' do
            expect { client.notification(body) }.not_to raise_error
          end

          it 'returns successful response' do
            response = client.notification(body)

            expect(response.status).to eq('successful')
            expect(response.transaction_type).to eq('payment')
            expect(response.transaction.uid).to eq('1-fc77f1e8f0')
            expect(response.transaction.credit_card['stamp']).to eq('a825df7faba8804619aef7a6d5a5821ec292fce04e3e43933ca33d0692df90b4')
          end
        end
      end
    end

    context 'failed request' do
      let(:response_body) do
        {
          'response' => {
            'message' => "Currency can't be blank. Description can't be blank. Amount can't be blank",
            'errors' => {
              'currency' => ["can't be blank"],
              'description' => ["can't be blank"],
              'amount' => ['must be greater than 0']
            }
          }
        }
      end

      before do
        request_params.tap do |hsh|
          hsh['amount'] = nil
          hsh['description'] = nil
          hsh['amount'] = 0
        end
      end

      let(:failed_response) { OpenStruct.new(status: 422, body: response_body) }
      before { allow_any_instance_of(Faraday::Connection).to receive(:post).and_return(failed_response) }

      it 'returns errors' do
        response = client.authorize(request_params)

        expect(response.errors.amount).to eq(['must be greater than 0'])
      end
    end
  end

  describe 'Transaction Recovery Service' do
    let(:client) { described_class.new(params) }
    let(:successful_response) { OpenStruct.new(status: 200, body: response_body) }

    before do
      allow_any_instance_of(Faraday::Connection).to receive(:post)
                                                .with(path, request: request_params)
                                                .and_return(successful_response)
    end

    context 'transaction renotification' do
      let(:request_params) { { uid: '123-uid' } }
      let(:response_body) { { 'response' => { 'message' => 'Transaction was renotified' } } }
      let(:path) { '/transactions/123-uid/renotify' }

      it 'returns message' do
        res = client.renotify(request_params)

        expect(res.response['message']).to eq('Transaction was renotified')
      end
    end

    context 'transaction recover' do
      let(:response_body) { { 'response' => { 'message' => "Transaction 123-uid was updated" } } }
      let(:path) { '/transactions/123-uid/recover' }
      let(:request_params) { { uid: '123-uid', status: 'failed', rrn: '333', bank_code: '111' } }

      it 'returns message' do
        res = client.recover(request_params)

        expect(res.response['message']).to eq("Transaction 123-uid was updated")
      end
    end
  end
end
