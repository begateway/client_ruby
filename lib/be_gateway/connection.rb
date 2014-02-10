module BeGateway
  module Connection
    extend ActiveSupport::Concern
    extend Forwardable
    def_delegators :connection, :headers, :headers=
    
    attr_reader :options

    included do
      cattr_accessor :rack_app, :stub_app, :proxy
    end

    def initialize(params)
      @login = params[:shop_id]
      @password = params[:secret_key]
      @url = params[:url]
      @options = params[:options] || {}
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
      rescue Faraday::Error::ClientError => e
        ErrorResponse.new({ body: { status: 'error', message: 'Gateway is temporarily unavailable', error: e.message } })
      end
    end

    def connection
      @connection ||= Faraday.new(url, options || {}) do |conn|
        conn.request :json
        conn.request :basic_auth, login, password
        
        conn.response :json
        conn.response :logger, logger
        
        conn.proxy(proxy) if proxy

        conn.adapter :test, stub_app if stub_app
        conn.adapter :rack, rack_app.new if rack_app
        if !stub_app && !rack_app
          conn.adapter Faraday.default_adapter
        end
      end
    end
    
    def logger
      log = options[:logger] || Logger.new(STDOUT)
      log.level = Logger::INFO
      log
    end
    
  end
end