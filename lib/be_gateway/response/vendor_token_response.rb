module BeGateway
  class VendorTokenResponse < OpenStruct
    def successful?
      !card_token.nil?
    end

    def invalid?
      !successful?
    end

    def message
      self.dig('response', 'message')
    end
  end
end
