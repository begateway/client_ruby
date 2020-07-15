module BeGateway
  module Connection
    extend ActiveSupport::Concern
    extend Forwardable
    def_delegators :connection, :headers, :headers=

    attr_reader :opts

    included do
      cattr_accessor :stub_app, :proxy, :logger
    end

    def initialize(params)
      @login = params.fetch(:shop_id)
      @password = params.fetch(:secret_key)
      @url = params.fetch(:url)
      @opts = params[:options] || {}
      @rack_app = params[:rack_app]
      @passed_headers = params[:headers]
    end

    attr_reader :passed_headers

    private

    attr_reader :login, :password, :url, :rack_app

    DEFAULT_OPEN_TIMEOUT = 5
    DEFAULT_TIMEOUT = 25

    def send_request(method, path, params = nil)
      r = begin
            connection.public_send(method, path, params)
          rescue Faraday::ClientError => e
            logger.error("Connection error to '#{path}': #{e}") if logger

            OpenStruct.new(
              status: 500,
              body: {
                'response' => {
                  'message' => 'Gateway is temporarily unavailable',
                  'errors' => {
                    'gateway' => 'is temporarily unavailable'
                  }
                }
              }
            )
          end

      logger.info("[beGateway client response body] #{r.body}") if logger

      (200..299).cover?(r.status) ? Response.new(r) : ErrorResponse.new(r)
    end

    def connection
      @connection ||= Faraday::Connection.new(url, opts || {}) do |conn|
        conn.options[:open_timeout] ||= DEFAULT_OPEN_TIMEOUT
        conn.options[:timeout] ||= DEFAULT_TIMEOUT
        conn.options[:proxy] = proxy if proxy
        conn.headers = passed_headers if passed_headers
        conn.request :json
        conn.request :basic_auth, login, password
        conn.response :json
        conn.response :logger, logger
        if stub_app
          conn.adapter :test, stub_app
        elsif rack_app
          conn.adapter :rack, rack_app.new
        else
          conn.adapter Faraday.default_adapter
        end
      end
    end

    def logger
      (opts[:logger] || Logger.new(STDOUT)).tap { |l| l.level = Logger::INFO }
    end
  end
end
