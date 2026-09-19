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

    context 'logging' do
      let(:io)            { StringIO.new }
      let(:io_logger)     { Logger.new(io) }
      let(:credentials)   { ["#{params[:shop_id]}:#{params[:secret_key]}"].pack('m0') }
      let(:response_body) { {'transaction' => {'credit_card' => {'token' => 'card-token'}}} }

      before do
        test_class.stub_app = Faraday::Adapter::Test::Stubs.new do |stub|
          stub.post(path) { [200, {}, response_body] }
        end
      end

      after do
        test_class.logger = nil
        test_class.stub_app = nil
      end

      context 'when logger is not set' do
        it 'writes nothing to stdout' do
          expect { subject }.not_to output.to_stdout
        end
      end

      context 'when logger is set' do
        before { test_class.logger = io_logger }

        it 'logs the request with masked credentials' do
          subject

          expect(io.string).to include('POST', path, 'Authorization: "Basic [FILTERED]"')
          expect(io.string).not_to include(credentials)
          expect(io.string).not_to include(params[:secret_key])
        end

        it 'does not log response body at INFO' do
          io_logger.level = Logger::INFO
          subject

          expect(io.string).not_to include('card-token')
        end

        it 'logs response body at DEBUG' do
          io_logger.level = Logger::DEBUG
          subject

          expect(io.string).to include('card-token')
        end
      end

      context 'when logger is passed within options' do
        before { params.merge!(options: { logger: io_logger }) }

        it 'logs to the passed logger' do
          subject

          expect(io.string).to include('POST', path)
        end

        it 'keeps the level of the passed logger' do
          io_logger.level = Logger::WARN
          subject

          expect(io_logger.level).to eq(Logger::WARN)
        end
      end
    end
  end

end
