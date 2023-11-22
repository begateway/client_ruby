module BeGateway
  class Client
    include Connection

    TRANSACTIONS = %w(authorize authorization capture void payment credit payout chargeback
                      fraud_advice refund checkup p2p tokenization recipient_tokenization).freeze

    TRANSACTIONS.each do |tr_type|
      define_method tr_type.to_sym do |params|
        send_request('post', action_url(tr_type), request: params)
      end
    end

    def charge(params)
      path = 'services/credit_cards/charges'
      send_request('post', path, request: params)
    end

    def finalize_3ds(params)
      path = "/process/#{params[:uid]}/return"
      send_request('post', path, params)
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
      Response.new(Struct.new(:status, :body).new(200, params))
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

    def renotify(params)
      path = "/transactions/#{params[:uid]}/renotify"
      send_request('post', path, request: params)
    end

    def recover(params)
      path = "/transactions/#{params[:uid]}/recover"
      send_request('post', path, request: params)
    end

    def confirm(params)
      path = "/transactions/#{params[:uid]}/confirm"
      send_request('post', path, request: params)
    end

    def proof(params)
      path = "/transactions/#{params[:uid]}/proof"
      send_request('post', path, request: params)
    end

    private

    def action_url(tr_type)
      if tr_type == 'authorize'
        logger.warn "Method 'authorize' was deprecated! Please, use 'authorization' for BeGateway::Client." if logger
        '/transactions/authorizations'
      else
        "/transactions/#{tr_type}s"
      end
    end
  end
end
