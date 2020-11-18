require 'spec_helper'

describe BeGateway::Checkout do
  let(:params) do
    {
      shop_id: 1,
      secret_key: 'secret_key',
      url: 'https://gateway.ecomcharge.com'
    }
  end
  let(:checkout) { described_class.new(params) }

  describe "checkout" do
    let(:request_params) do
      {
        'transaction_type' => 'payment',
        'settings' => {
          'success_url' => 'http://127.0.0.1:4567/success',
          'decline_url' => 'http://127.0.0.1:4567/decline',
          'fail_url' => 'http://127.0.0.1:4567/fail',
          'cancel_url' => 'http://127.0.0.1:4567/cancel',
          'notification_url' => 'http://your_shop.com/notification',
          'language' => "en",
          'customer_fields' => {
            'hidden' => ['phone'],
            'read_only' => ['email']
          }
        },
        'order' => {
          'currency' => 'GBP',
          'amount' => 4299,
          'description' => 'Order description'
        },
        'customer' => {
          'address' => 'Baker street 221b',
          'country' => 'GB',
          'city' => 'London',
          'email' => 'jake@example.com'
        }
      }
    end
    let(:successful_response) { OpenStruct.new(status: 200, body: response_body) }

    context "successful request" do
      before do
        allow_any_instance_of(Faraday::Connection)
          .to receive(:post)
          .with('/ctp/api/checkouts', checkout: request_params.merge(:version => '2.1'))
          .and_return(successful_response)
      end

      describe "#get_token" do
        let(:response_body) do
          {
            'checkout' => { 'token' => '3241e439f8c87d941d92621a4bdc030d4c9a69c67f3b0cfe12de4a13cc34aa51' }
          }
        end

        it 'sends checkout request' do
          response = checkout.get_token(request_params)

          expect(response.successful?).to eq(true)
          expect(response['checkout']['token']).to eq('3241e439f8c87d941d92621a4bdc030d4c9a69c67f3b0cfe12de4a13cc34aa51')
        end
      end

      describe "#query" do
        let(:response_body) do
          {
            'checkout' => {
              'token' => '3241e439f8c87d941d92621a4bdc030d4c9a69c67f3b0cfe12de4a13cc34aa51',
              'shop_id' => 1,
              'transaction_type' => 'payment',
              'gateway_response' => {
                'payment' => {
                   'uid' => '1891-5fcb2bda3b',
                   'auth_code' =>'654321',
                   'bank_code' =>'05',
                   'rrn' =>'999',
                   'ref_id' =>'777888',
                   'message' =>'Payment was approved',
                   'gateway_id' =>317,
                   'billing_descriptor' =>'TEST GATEWAY BILLING DESCRIPTOR',
                   'status' =>'successful'
                }
              },
              'order' => {
                'currency' => 'GBP',
                'amount' => 4299,
                'description' => 'New description'
              },
              'settings' => {
                'success_url' => 'http://127.0.0.1:3003/success',
                'fail_url' => 'http://127.0.0.1:3003/fail',
                'decline_url' => 'http://127.0.0.1:3003/declined',
                'language' => 'en'
              },
              'customer' => {
                'address' => 'Baker street 221b',
                'country' => 'GB',
                'city' => 'London',
                'email' => 'jake@example.com'
              },
              'finished' => true
            }
          }
        end

        before do
          allow_any_instance_of(Faraday::Connection).to receive(:get)
            .with('3241e439f8c87d941d92621a4bdc030d4c9a69c67f3b0cfe12de4a13cc34aa51')
            .and_return(successful_response)
        end

        it 'sends query request' do
          response = checkout.get_token(request_params)

          expect(response.successful?).to eq(true)
          expect(response['checkout']['token']).to eq('3241e439f8c87d941d92621a4bdc030d4c9a69c67f3b0cfe12de4a13cc34aa51')
          expect(response['checkout']['order']['currency']).to eq('GBP')
          expect(response['checkout']['gateway_response']['payment']['uid']).to eq('1891-5fcb2bda3b')
        end
      end
    end

    context "failed request" do
      let(:response_body) do
        {
          'response' => {
            'errors' => {
              'settings' => ['is invalid'],
              'order' => ['is invalid'],
              'settings.fail_url' => ['does not appear to be valid'],
              'order.currency' =>['is invalid']
            },
            'message' => 'BIG ERROR IS RECEIVED!!!'
          }
        }
      end

      let(:failed_response) { OpenStruct.new(status: 422, body: response_body) }
      before { allow_any_instance_of(Faraday::Connection).to receive(:post).and_return(failed_response) }

      context "#get_token" do
        it 'gets errors and error message' do
          response = checkout.get_token(request_params)

          expect(response.invalid?).to eq(true)
          expect(response.errors).not_to be_nil
          expect(response.message).to eq 'BIG ERROR IS RECEIVED!!!'
        end
      end
    end

    context 'Faraday client raises an error' do
      before do
        allow_any_instance_of(Faraday::Connection).to receive(:public_send).and_raise(Faraday::ClientError, "Houston, we've got a problem")
      end

      it 'returns an error response' do
        response = checkout.get_token({})
        expect(response.invalid?).to eq(true)
        expect(response.message).to eq('Gateway is temporarily unavailable')
        expect(response.errors.gateway).to eq('is temporarily unavailable')
      end
    end
  end
end
