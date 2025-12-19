module BeGateway
  class Client
    include Connection

    TRANSACTIONS = %w(authorize authorization capture void payment credit payout chargeback
                      fraud_advice refund checkup p2p tokenization recipient_tokenization).freeze

    TRANSACTION_OPERATIONS = %w(renotify recover confirm proof).freeze

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

    def bank_names(params)
      send_request('get', '/bank_names', params)
    end

    def bank_name(id:)
      send_request('get', "/bank_names/#{id}")
    end

    def update_bank_name(id:, params:)
      send_request('patch', "/bank_names/#{id}", params)
    end

    def issuers(params)
      send_request('get', "/bank_names/issuers", params)
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

    TRANSACTION_OPERATIONS.each do |op_type|
      define_method op_type.to_sym do |params|
        send_request('post', action_url_for_operation(op_type, params[:uid]), request: params)
      end
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

    def action_url_for_operation(type, uid)
      "/transactions/#{uid}/#{type}"
    end
  end
end
