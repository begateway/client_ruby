module BeGateway
  class Response < OpenStruct
    def initialize(response)
      @params = response
      
      super(response)
    end

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
    
    def to_params
      params
    end

    private

    attr_reader :params
  end
end
