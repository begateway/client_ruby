module BeGateway
  class Client
    include Connection

    TRANSACTIONS = %w(authorize capture void payment credit payout chargeback
                      fraud_advice refund checkup p2p tokenization).freeze

    TRANSACTIONS.each do |tr_type|
      define_method tr_type.to_sym do |params|
        send_request('post', action_url(tr_type), request: params)
      end
    end

    def verify_p2p(params)
      BeGateway::VerifyP2p.new(send_request('post', '/p2p-restrictions', request: params).to_params)
    end

    def query(params)
      path = params[:tracking_id] ? "/transactions/tracking_id/#{params[:tracking_id]}" : "/transactions/#{params[:id]}"
      send_request('get', path)
    end

    def close_days(params)
      path = '/transactions/close_days'
      send_request('post', path, request: params)
    end

    def notification(params)
      Response.new(params)
    end

    def create_card(params)
      send_request('post', '/credit_cards', request: params)
    end

    def update_card_by_token(token, params)
      send_request('post', "/credit_cards/#{token}", request: params)
    end

    def v2_create_card(params)
      send_request('post', '/v2/credit_cards', request: params)
    end

    def v2_update_card_by_token(token, params)
      send_request('put', "/v2/credit_cards/#{token}", request: params)
    end

    private

    def action_url(tr_type)
      if tr_type == 'authorize'
        '/transactions/authorizations'
      else
        "/transactions/#{tr_type}s"
      end
    end
  end
end
