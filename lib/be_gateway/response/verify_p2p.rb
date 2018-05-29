module BeGateway
  class VerifyP2p < OpenStruct

    def successful?
      status == "successful"
    end

    def error?
      !error_code.nil?
    end

  end
end
