require 'faraday'
require 'faraday_middleware'

module BeGateway
  class Client
    include Connection
    
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

    def chargeback(params)
      response = post "/transactions/chargebacks", { request: params }
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
  end
end
