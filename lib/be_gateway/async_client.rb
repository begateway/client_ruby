module BeGateway
  class AsyncClient < Client
    def result(params)
      path = "/async/result/#{params[:request_id]}"
      send_request('get', path)
    end

    private

    def action_url(tr_type)
      "/async#{super}"
    end
  end
end
