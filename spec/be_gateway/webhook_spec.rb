require 'spec_helper'

describe BeGateway::Webhook do
  describe '.valid_signature?' do
    let(:key) { OpenSSL::PKey::RSA.new(2048) }
    let(:body) { '{"transaction":{"uid":"1-310b0da80b","status":"successful","tracking_id":"order-123"}}' }
    let(:signature) { [key.sign(OpenSSL::Digest::SHA256.new, body)].pack('m0') }
    let(:public_key) { [key.public_to_der].pack('m0') }

    it 'returns true for a valid signature with a base64 DER key' do
      expect(described_class.valid_signature?(body, signature, public_key)).to eq(true)
    end

    it 'returns true for a valid signature with a PEM key' do
      expect(described_class.valid_signature?(body, signature, key.public_to_pem)).to eq(true)
    end

    it 'returns false when the body is changed' do
      expect(described_class.valid_signature?(body.sub('1', '2'), signature, public_key)).to eq(false)
    end

    it 'returns false for a signature made by another key' do
      other_key = [OpenSSL::PKey::RSA.new(2048).public_to_der].pack('m0')

      expect(described_class.valid_signature?(body, signature, other_key)).to eq(false)
    end

    it 'returns false for a blank signature' do
      expect(described_class.valid_signature?(body, '', public_key)).to eq(false)
      expect(described_class.valid_signature?(body, nil, public_key)).to eq(false)
    end

    it 'returns false for a garbage public key' do
      expect(described_class.valid_signature?(body, signature, 'not a key')).to eq(false)
    end
  end

  describe '.valid_authorization?' do
    let(:header) { 'Basic MTpzZWNyZXRfa2V5' }

    it 'returns true for the shop credentials' do
      expect(described_class.valid_authorization?(header, shop_id: 1, secret_key: 'secret_key')).to eq(true)
    end

    it 'returns false for a wrong secret key' do
      expect(described_class.valid_authorization?(header, shop_id: 1, secret_key: 'wrong')).to eq(false)
    end

    it 'returns false for a missing header' do
      expect(described_class.valid_authorization?(nil, shop_id: 1, secret_key: 'secret_key')).to eq(false)
      expect(described_class.valid_authorization?('', shop_id: 1, secret_key: 'secret_key')).to eq(false)
    end
  end
end
