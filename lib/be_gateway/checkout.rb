module BeGateway
  class Checkout
    include Connection

    def get_token(params)
      params[:version] ||= params['version'] || '2.1'
      send_request('post', '/ctp/api/checkouts', checkout: params)
    end

    def query(token)
      send_request('get', "/ctp/api/checkouts/#{token}")
    end
  end
end
