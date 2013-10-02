module BeGateway
  class Checkout
    include Connection
    
    def get_token(params)
      response = post "/api/checkouts", { checkout: params }
      make_response(response)
    end
    
    def query(token)
      response = get "/api/checkouts/#{token}"
      make_response(response)
    end
  end
end
