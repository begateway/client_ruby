require 'spec_helper'

describe 'BeGateway::Connection' do
  let(:test_class) { Class.new { include BeGateway::Connection } }
  let(:headers)    { nil }
  let(:params) do
    {
      shop_id: 1,
      secret_key: 'secret_key',
      url: 'https://gateway.ecomcharge.com',
      headers: headers
    }
  end
  let(:client) { test_class.new(params) }

  context '.connection' do
    subject { client.send(:connection) }

    context 'when passed headers' do
      let(:headers) { {'RequestID' => 'some-request-id'} }

      it 'contains passed headers' do
        expect(subject.headers).to include(headers)
      end
    end

    context 'when global proxy is set' do
      let(:proxy) { 'http://example.com' }

      before { test_class.proxy = proxy }

      it 'uses proxy' do
        expect(subject.proxy.uri.to_s).to eq(proxy)
      end
    end

    context 'when proxy passed within options' do
      let(:proxy) { 'http://example.com' }

      before { params.merge!(options: { proxy: proxy }) }

      it 'uses optional proxy' do
        expect(subject.proxy.uri.to_s).to eq(proxy)
      end

      it 'does not have global proxy' do
        expect(test_class.proxy).to be(nil)
      end
    end

    context 'when both proxies are set' do
      let(:global_proxy)   { 'http://example.com:3333' }
      let(:optional_proxy) { 'http://example.com:4444' }

      before { test_class.proxy = global_proxy }
      before { params.merge!(options: { proxy: optional_proxy }) }

      it 'uses optional proxy' do
        expect(subject.proxy.uri.to_s).to eq(optional_proxy)
      end
    end
  end

  context '.send_request' do
    let(:method) { 'post' }
    let(:path)   { '/payment' }
    let(:data)   { {amount: 100} }
    let(:connection) { double('connection') }

    subject { client.send(:send_request, method, path, data) }

    it 'calls passed method for the connection' do
      expect(Faraday::Connection).to receive(:new).and_return(connection)

      expect(connection).to receive(:public_send)
        .with(method, path, data)
        .and_return(OpenStruct.new)

      subject
    end

    context 'when request fails' do
      let(:error) { Faraday::TimeoutError.new('execution expired') }
      let(:stub_app) do
        Faraday::Adapter::Test::Stubs.new { |stub| stub.post(path) { raise error } }
      end

      before { test_class.stub_app = stub_app }
      after  { test_class.stub_app = nil }

      it 'returns failed response' do
        expect(subject).to be_a(BeGateway::ErrorResponse)
        expect(subject.code).to eq(500)
        expect(subject.message).to eq('Gateway is temporarily unavailable')
      end

      context 'with raise_errors' do
        before { params.merge!(raise_errors: true) }

        it 'raises connection error on timeout' do
          expect { subject }.to raise_error(BeGateway::ConnectionError, 'execution expired') { |e|
            expect(e.cause).to be(error)
          }
        end

        context 'when connection failed' do
          let(:error) { Faraday::ConnectionFailed.new('Connection refused') }

          it 'raises connection error' do
            expect { subject }.to raise_error(BeGateway::ConnectionError, 'Connection refused')
          end
        end

        context 'when other error is raised' do
          let(:error) { RuntimeError.new('boom') }

          it 'raises original error' do
            expect { subject }.to raise_error(RuntimeError, 'boom')
          end
        end

        context 'when gateway answers with error' do
          let(:body) { { 'response' => { 'message' => 'Amount is invalid', 'errors' => { 'amount' => ['is invalid'] } } } }
          let(:stub_app) do
            Faraday::Adapter::Test::Stubs.new { |stub| stub.post(path) { [422, {}, body] } }
          end

          it 'returns error response' do
            expect(subject).to be_a(BeGateway::ErrorResponse)
            expect(subject.code).to eq(422)
            expect(subject.message).to eq('Amount is invalid')
          end
        end

        context 'when gateway answers with html page' do
          let(:stub_app) do
            Faraday::Adapter::Test::Stubs.new do |stub|
              stub.post(path) { [502, { 'Content-Type' => 'text/html' }, '<html>Bad Gateway</html>'] }
            end
          end

          it 'returns failed response' do
            expect(subject).to be_a(BeGateway::ErrorResponse)
            expect(subject.code).to eq(500)
          end
        end

        context 'when api version 3 is used' do
          before { params.merge!(version: 3) }

          it 'raises connection error on timeout' do
            expect { subject }.to raise_error(BeGateway::ConnectionError)
          end
        end
      end
    end
  end

end
