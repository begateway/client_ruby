module BeGateway
  class Response
    def initialize(response)
      @params = response
    end

    def transaction
      Transaction.new(params["transaction"])
    end

    def invalid?
      false
    end
    
    def transaction_type
      @params["transaction"]["type"]
    end

    private

    attr_reader :params
  end
end
