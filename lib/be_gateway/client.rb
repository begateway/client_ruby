require 'faraday'
require 'faraday_middleware'

module BeGateway
  class Client
    cattr_accessor :rack_app, :stub_app, :proxy
    attr_reader :options

    def initialize(params)
      @login = params[:shop_id]
      @password = params[:secret_key]
      @url = params[:url]
      @options = params[:options]
    end

    def authorize(params)
      response = post "/transactions/authorizations", { request: params }
      make_response(response)
    end

    def capture(params)
      response = post "/transactions/captures", { request: params }
      make_response(response)
    end

    def void(params)
      response = post "/transactions/voids", { request: params }
      make_response(response)
    end

    def payment(params)
      response = post "/transactions/payments", { request: params }
      make_response(response)
    end

    def credit(params)
      response = post "/transactions/credits", { request: params }
      make_response(response)
    end

    def query(params)
      path = params[:tracking_id] ? "/transactions/tracking_id/#{params[:tracking_id]}" : "/transactions/#{params[:id]}"
      response = get(path)
      make_response(response)
    end

    def refund(params)
      response = post "/transactions/refunds", { request: params }
      make_response(response)
    end

    def notification(params)
      Response.new(params)
    end

    private

    attr_reader :login, :password, :url

    def make_response(response)
      response.status == 200 ? Response.new(response.body) : ErrorResponse.new(response.body)
    end

    def post(path, params)
      send_request('post', path, params)
    end

    def get(path)
      send_request('get', path)
    end

    def send_request(method, path, params = nil)
      begin
        connection.public_send(method, path, params)
      rescue Faraday::Error::ClientError=> e
        ErrorResponse.new({ body: { status: 503, message: 'Gateway is temporarily unavailable', error: e.message } })
      end
    end

    def connection
      @connection ||= Faraday.new(url, options = {}) do |conn|
        conn.request :json
        conn.request :basic_auth, login, password

        conn.response :json

        conn.proxy(proxy) if proxy

        conn.adapter :test, stub_app if stub_app
        conn.adapter :rack, rack_app.new if rack_app
        if !stub_app && !rack_app
          conn.adapter Faraday.default_adapter
        end
      end
    end
  end
end
