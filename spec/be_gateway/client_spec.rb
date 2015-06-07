require 'spec_helper'

describe BeGateway::Client do
  let(:params) {
    {
      shop_id: 1,
      secret_key: 'secret_key',
      url: 'https://gateway.ecomcharge.com'
    }
  }

  describe "#initialize" do
    before { params.delete(:shop_id) }

    it 'raises error for required attributes' do
      expect { described_class.new(params) }.to raise_error('key not found: :shop_id')
    end
  end

  describe "transaction" do
    let(:client) { described_class.new(params) }
    let(:request_params) {
      {
        "amount" => 100,
        "currency" => "USD",
        "description" => "Test transaction",
        "tracking_id" => "your_uniq_number",
        "language" => "en",
        "billing_address" => {
           "first_name" => "John",
           "last_name" => "Doe",
           "country" => "US",
           "city" => "Denver",
           "state" => "CO",
           "zip" => "96002",
           "address" => "1st Street"
        },
        "credit_card" => {
           "number" => "4200000000000000",
           "verification_value" => "123",
           "holder" => "John Doe",
           "exp_month" => "05",
           "exp_year" => "2020"
        },
        "customer" => {
           "ip" => "127.0.0.1",
           "email" => "john@example.com"
        }
      }
    }

    context "successful request" do
      let(:response_body) {
        {
          "transaction" => {
             "customer" => {
                "ip" => "127.0.0.1",
                "email" => "john@example.com"
             },
             "credit_card" => {
                "holder" => "John Doe",
                "stamp" => "3709786942408b77017a3aac8390d46d77d181e34554df527a71919a856d0f28",
                "token" => "40bd001563085fc35165329ea1ff5c5ecbdbbeef40bd001563085fc35165329e",
                "brand" => "visa",
                "last_4" => "0000",
                "first_1" => "4",
                "exp_month" => 5,
                "exp_year" => 2015
             },
             "billing_address" => {
                "first_name" => "John",
                "last_name" => "Doe",
                "address" => "1st Street",
                "country" => "US",
                "city" => "Denver",
                "zip" => "96002",
                "state" => "CO"
             },
             "authorization" => {
                "auth_code" => "654321",
                "bank_code" => "00",
                "rrn" => "999",
                "ref_id" => "777888",
                "message" => "The operation was successfully processed.",
                "gateway_id" => 317,
                "billing_descriptor" => "TEST GATEWAY BILLING DESCRIPTOR",
                "status" => "successful"
             },
             "uid" => "4107-310b0da80b",
             "status" => "successful",
             "message" => "Successfully processed",
             "amount" => 100,
             "currency" => "USD",
             "description" => "Test order",
             "type" => "authorization",
             "tracking_id" => "your_uniq_number",
             "language" => "en"
          }        
        }  
      }
      let(:successful_response) { OpenStruct.new(status: 200, body: response_body) }
      before { allow(client).to receive(:post).with(any_args).and_return(successful_response) }

      it 'returns transaction information' do
        response = client.authorize(request_params)

        expect(response.successful?).to eq(true)
        expect(response.transaction['currency']).to eq('USD')
        expect(response.transaction['amount']).to eq(100)
        expect(response.transaction['credit_card']['token']).to eq('40bd001563085fc35165329ea1ff5c5ecbdbbeef40bd001563085fc35165329e')
        expect(response.transaction['customer']['ip']).to eq('127.0.0.1')
        expect(response.transaction['billing_address']['first_name']).to eq('John')
        expect(response.transaction['uid']).to eq('4107-310b0da80b')
      end

      describe "#authorize" do
        it 'sends authorization request' do
          response = client.authorize(request_params)

          expect(response.transaction['type']).to eq('authorization')
          expect(response.transaction['authorization']['auth_code']).to eq('654321')
        end
      end

      describe "#payment" do
        before do
          response_body["transaction"].tap do |hsh|
            hsh.delete("authorization")
            hsh["payment"] = {
              "auth_code" => "654321",
              "bank_code" => "00",
              "rrn" => "999",
              "ref_id" => "777888",
              "message" => "The operation was successfully processed.",
              "gateway_id" => 317,
              "billing_descriptor" => "TEST GATEWAY BILLING DESCRIPTOR",
              "status" => "successful"
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

      context "child" do
        %w(capture void refund).each do |tr_type|
          describe "##{tr_type}" do
            let(:request_params) {
              {}.tap do |hsh|
                hsh['parent_uid'] = '4107-310b0da80b',
                hsh['amount'] = 100
                hsh['reason'] = 'Client request' if tr_type == 'refund'
              end
            }
            before do
              response_body["transaction"].tap do |hsh|
                hsh.delete("authorization")
                hsh["#{tr_type}"] = {
                  "message" => "The operation was successfully processed.",
                  "ref_id" => "8889999",
                  "gateway_id" => 152,
                  "status" => "successful"
                }
                hsh["type"] = tr_type
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

      context "#credit" do
        let(:request_params) {
          {
            "amount" => 100,
            "currency" => "USD",
            "description" => "Test transaction",
            "tracking_id" => "tracking_id_000",
            "language" =>"en",
            "credit_card" => {
              "token" => "40bd001563085fc35165329ea1ff5c5ecbdbbeef40bd001563085fc35165329e"
            }
          }
        }

        before do
          response_body["transaction"].tap do |hsh|
            hsh.delete("authorization")
            hsh["credit"] = {
              "auth_code" => "654327",
              "bank_code" => "00",
              "rrn" => "934",
              "ref_id" => "777822",
              "message" => "Credit was approved",
              "gateway_id" => 2124,
              "billing_descriptor" => "TEST GATEWAY BILLING DESCRIPTOR",
              "status" => "successful"
            }
            hsh["type"] = 'credit'
          end
        end

        it 'sends credit request' do
          response = client.credit(request_params)

          expect(response.transaction['type']).to eq('credit')
          expect(response.transaction['credit']['ref_id']).to eq('777822')
          expect(response.transaction['credit']['rrn']).to eq('934')
        end
      end

      context "other" do
        context "#query" do
          before { allow(client).to receive(:get).with(any_args).and_return(successful_response) }
          let(:request_params) { { id: '4107-310b0da80b' } }
          
          it 'sends query request' do
            response = client.query(request_params)

            expect(response.transaction['currency']).to eq('USD')
            expect(response.transaction['amount']).to eq(100)
            expect(response.transaction['credit_card']['token']).to eq('40bd001563085fc35165329ea1ff5c5ecbdbbeef40bd001563085fc35165329e')
          end
        end

        context "#checkup" do
          before do
            response_body["transaction"].tap do |hsh|
              hsh["be_protected_verification"] = {
                "status" => "successful",
                "white_black_list" => {
                  "email" => "absent",
                  "ip" => "absent",
                  "card_number" => "white"
                },
                "rules" => {
                  "1_123_My Shop" => {
                    "more_100_eur" => {"Transaction amount more than 100 AND Transaction currency is EUR" => "passed"}
                  },
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
      end
    end

    context "failed request" do
      let(:response_body) {
        {
          "message" => "Currency can't be blank. Description can't be blank. Amount can't be blank",
          "errors" => {
            "currency" => ["can't be blank"],
            "description" => ["can't be blank"],
            "amount" => ["must be greater than 0"]
          }
        }
      }

      before do
        request_params.tap do |hsh|
          hsh['amount'] = nil
          hsh['description'] = nil
          hsh['amount'] = 0
        end
      end

      let(:failed_response) { OpenStruct.new(status: 422, body: response_body) }
      before { allow(client).to receive(:post).with(any_args).and_return(failed_response) }

      it 'returns errors' do
        response = client.authorize(request_params)

        expect(response['errors']['amount']).to eq(["must be greater than 0"])
      end

    end
  end

end
