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
      before { params.merge!(options: { read_timeout: 60 }) }

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
  end

end
