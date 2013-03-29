require 'faraday'
require 'faraday_middleware'

module BeGateway
  class Client
    cattr_accessor :rack_app
    cattr_accessor :rack_app, :stub_app

    def initialize(params)
      @login = params[:shop_id]
      @password = params[:secret_key]
      @url = params[:url]
    end

    def authorize(params)
      response = post "/transactions/authorizations", { request: params }
      make_response(response)
    end

    def payment(params)
      response = post "/transactions/payments", { request: params }
      make_response(response)
    end

    def query(params)
      response = get "/transactions/#{params[:id]}"
      make_response(response)
    end

    def refund(params)
      response = post "/transactions/refunds", { request: params }
      make_response(response)
    end

    private

    attr_reader :login, :password, :url

    def make_response(response)
      response.status == 200 ? Response.new(response) : ErrorResponse.new(response)
    end

    def post(path, params)
      connection.post(path, params)
    end

    def get(path)
      connection.get(path)
    end

    def connection
      @connection ||= Faraday.new(url: url) do |conn|
        conn.request :json
        conn.request :basic_auth, login, password

        conn.response :json

        conn.adapter :test, stub_app if stub_app
        conn.adapter :rack, rack_app.new if rack_app
      end
    end
  end
end
