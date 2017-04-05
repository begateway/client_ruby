module BeGateway
  class Checkout
    include Connection

    def get_token(params)
      post('/ctp/api/checkouts', checkout: params)
    end

    def query(token)
      get("/ctp/api/checkouts/#{token}")
    end
  end
end
