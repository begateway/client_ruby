module BeGateway
  class Response
    def initialize(response)
      @params = response.body
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
