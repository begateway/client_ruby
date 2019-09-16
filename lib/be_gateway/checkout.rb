module BeGateway
  class Checkout
    include Connection

    def get_token(params)
      send_request('post', '/ctp/api/checkouts', checkout: params.merge('version' => '2.1'))
    end

    def query(token)
      send_request('get', "/ctp/api/checkouts/#{token}")
    end
  end
end
