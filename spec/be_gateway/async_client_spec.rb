require 'spec_helper'

describe BeGateway::AsyncClient do
  let(:params) do
    {
      shop_id: 1,
      secret_key: 'secret_key',
      url: 'https://gateway.ecomcharge.com'
    }
  end

  describe 'async methods' do
    let(:client) { described_class.new(params) }
    let(:successful_response) { OpenStruct.new(status: 200, body: response_body) }

    context 'async transaction methods' do
      subject { client }

      it { should respond_to :payment }
      it { should respond_to :authorization }
      it { should respond_to :capture }
      it { should respond_to :void }
      it { should respond_to :credit }
      it { should respond_to :payout }
      it { should respond_to :refund }
    end

    context '#payment' do
      context 'success async response' do
        let(:request_params) {
          {
            'amount' => 100,
            'currency' => 'USD',
            'description' => 'Test transaction',
            'credit_card' => {
              'number' => '4200000000000000',
              'verification_value' => '123',
              'holder' => 'John Doe',
              'exp_month' => '05',
              'exp_year' => '2025'
            }
          }
        }
        let(:request_id) { 'fa8caf55-c845-4237-9056-e6a324d5f02d' }
        let(:response_body) { {"status" => "processing",
                               "request_id" => request_id,
                               "status_url" => "https://gateway.ecomcharge.com/async/status/#{request_id}",
                               "response_url" => "https://gateway.ecomcharge.com/async/result/#{request_id}"} }
        let(:path) { "/async/transactions/payments" }

        before do
          allow_any_instance_of(Faraday::Connection).to receive(:post)
                                                          .with(path, request: request_params)
                                                          .and_return(successful_response)
        end

        subject { client.payment(request_params) }

        it 'returns success response' do
          response = subject

          expect(response.status).to eq(200)
          expect(response.successful?).to eq(true)
          expect(response.failed?).to eq(false)
          expect(response.processing?).to eq(true)
          expect(response.body['status']).to eq('processing')
          expect(response.body['status_url']).to eq("https://gateway.ecomcharge.com/async/status/#{request_id}")
          expect(response.body['response_url']).to eq("https://gateway.ecomcharge.com/async/result/#{request_id}")
        end
      end
    end

    context '#result' do
      let(:request_id) { 'fa8caf55-c845-4237-9056-e6a324d5f02d' }
      let(:response_body) {
        {
          "transaction" => {
            "uid"=>"76505569-77ba8f7b53",
            "status"=>"successful",
            "amount"=>100,
            "currency"=>"USD",
            "description"=>"Test transaction ütf"
          }
        }
      }

      let(:path) { "/async/result/#{request_id}" }
      let(:request_params) { { request_id: request_id } }

      before do
        allow_any_instance_of(Faraday::Connection).to receive(:get)
                                                        .with(path, nil)
                                                        .and_return(successful_response)
      end

      it 'returns response' do
        res = client.result(request_params)

        expect(res.status).to eq(200)
        expect(res.successful?).to eq(true)
        expect(res.failed?).to eq(false)
        expect(res.processing?).to eq(false)
        expect(res.body['transaction']).to be_present
      end
    end

    context '#processing result' do
      let(:successful_response) { OpenStruct.new(status: 425, body: response_body) }
      let(:request_id) { 'fa8caf55-c845-4237-9056-e6a324d5f02d' }
      let(:response_body) {
        {"status" => "processing",
         "status_url" => "https://gateway.ecomcharge.com/async/status/#{request_id}",
         "response_url" => "https://gateway.ecomcharge.com/async/result/#{request_id}"}
      }

      let(:path) { "/async/result/#{request_id}" }
      let(:request_params) { { request_id: request_id } }

      before do
        allow_any_instance_of(Faraday::Connection).to receive(:get)
                                                        .with(path, nil)
                                                        .and_return(successful_response)
      end

      it 'returns response' do
        res = client.result(request_params)

        expect(res.status).to eq(425)
        expect(res.successful?).to eq(false)
        expect(res.failed?).to eq(false)
        expect(res.processing?).to eq(true)
      end
    end
  end
end
