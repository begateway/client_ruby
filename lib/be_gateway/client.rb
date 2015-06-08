module BeGateway
  class Client
    include Connection
    TRANSACTIONS = %w(authorize capture void payment credit chargeback fraud_advice refund checkup)

    TRANSACTIONS.each do |tr_type|
      define_method tr_type.to_sym do |params|
        response = post post_url(tr_type), { request: params }
        make_response(response)
      end
    end

    def query(params)
      path = params[:tracking_id] ? "/transactions/tracking_id/#{params[:tracking_id]}" : "/transactions/#{params[:id]}"
      response = get(path)
      make_response(response)
    end

    def notification(params)
      Response.new(params)
    end

    def create_card(params)
      response = post "/credit_cards", { request: params }
      make_response(response)
    end

    def create_card_by_token(token, params)
      response = post "/credit_cards/#{token}", { request: params }
      make_response(response)
    end

    private

    def post_url(tr_type)
      if tr_type == 'authorize'
        "/transactions/authorizations"
      else
        "/transactions/#{tr_type}s"  
      end
    end

  end
end
