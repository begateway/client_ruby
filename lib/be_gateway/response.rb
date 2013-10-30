module BeGateway
  class Response
    def initialize(response)
      @params = response
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
    
    def to_params
      params
    end

    private

    attr_reader :params
  end
end
