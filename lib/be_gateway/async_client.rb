module BeGateway
  class AsyncClient < Client
    def result(params)
      path = "/result/#{params[:request_id]}"
      send_request('get', path)
    end

    private

    def send_request(method, path, params = nil)
      super(method, async_path(path), params)
    end

    def async_path(path)
      "/async#{path}"
    end
  end
end
