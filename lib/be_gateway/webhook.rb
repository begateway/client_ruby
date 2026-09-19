require 'openssl'
require 'active_support/security_utils'

module BeGateway
  module Webhook
    def self.valid_signature?(raw_body, signature, public_key)
      key = public_key.to_s
      key = key.unpack1('m') unless key.include?('BEGIN PUBLIC KEY')
      OpenSSL::PKey::RSA.new(key).verify(OpenSSL::Digest::SHA256.new, signature.to_s.unpack1('m'), raw_body.to_s)
    rescue OpenSSL::PKey::PKeyError, ArgumentError
      false
    end

    def self.valid_authorization?(authorization_header, shop_id:, secret_key:)
      expected = "Basic #{["#{shop_id}:#{secret_key}"].pack('m0')}"
      ActiveSupport::SecurityUtils.secure_compare(authorization_header.to_s, expected)
    end
  end
end
