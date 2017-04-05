module BeGateway
  class Client
    include Connection

    TRANSACTIONS = %w(authorize capture void payment credit payout chargeback
                      fraud_advice refund checkup p2p tokenization).freeze

    TRANSACTIONS.each do |tr_type|
      define_method tr_type.to_sym do |params|
        post(transaction_url(tr_type), request: params)
      end
    end

    def query(params)
      path = params[:tracking_id] ? "/transactions/tracking_id/#{params[:tracking_id]}" : "/transactions/#{params[:id]}"
      get(path)
    end

    def close_days(params)
      path = '/transactions/close_days'
      post(path, request: params)
    end

    def notification(params)
      Response.new(params)
    end

    def create_card(params)
      post('/credit_cards', request: params)
    end

    def update_card_by_token(token, params)
      post("/credit_cards/#{token}", request: params)
    end

    def v2_create_card(params)
      post('/v2/credit_cards', request: params)
    end

    def v2_update_card_by_token(token, params)
      put("/v2/credit_cards/#{token}", request: params)
    end

    private

    def transaction_url(tr_type)
      if tr_type == 'authorize'
        '/transactions/authorizations'
      else
        "/transactions/#{tr_type}s"
      end
    end
  end
end
