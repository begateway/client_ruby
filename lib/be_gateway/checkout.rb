module BeGateway
  class Checkout
    include Connection
    
    def get_token(params)
      response = post "/ctp/api/checkouts", { checkout: params }
      make_response(response)
    end
    
    def query(token)
      response = get "/ctp/api/checkouts/#{token}"
      make_response(response)
    end
  end
end
