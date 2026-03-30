module BeGateway
  class VendorParentUidResponse < OpenStruct
    def successful?
      !transaction.nil?
    end

    def invalid?
      !successful?
    end

    def message
      self.dig('response', 'message')
    end
  end
end
