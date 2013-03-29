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

    private

    attr_reader :params
  end
end
