module BeGateway
  class Response < Base
    def successful?
      true
    end

    def status
      params["transaction"]["status"]
    end

    def transaction
      Transaction.new(params["transaction"])
    end

    def invalid?
      false
    end
    
    def transaction_type
      params["transaction"]["type"]
    end
  end
end
