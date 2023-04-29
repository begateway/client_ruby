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
      @version = params[:version]
    end

    attr_reader :passed_headers

    private

    attr_reader :login, :password, :url, :rack_app, :version

    DEFAULT_OPEN_TIMEOUT = 5
    DEFAULT_TIMEOUT = 25

    def send_request(method, path, params = nil)
      r = connection.public_send(method, path, params)

      logger.info("[beGateway client response body] #{r.body}") if logger

      build_response(r)
    rescue StandardError, Faraday::ClientError => e
      logger.error("Connection error to '#{path}': #{e}") if logger

      failed_response
    end

    def build_response(response)
      if version == 3
        BeGateway::V3::Response.new(response.status, response.body)
      else
        (200..299).cover?(response.status) ? Response.new(response) : ErrorResponse.new(response)
      end
    end

    def failed_response
      if version == 3
        BeGateway::V3::Response.new(
          500,
          {
            "code" => 'F.1000',
            "friendly_message" => 'We are sorry, but something went wrong.',
            "message" => 'Unknown error: Contact the payment service provider for details.',
            "errors" => {}
          }
        )
      else
        ErrorResponse.new(
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
        )
      end
    end

    def connection
      @connection ||= Faraday::Connection.new(url, opts || {}) do |conn|
        conn.options[:open_timeout] ||= DEFAULT_OPEN_TIMEOUT
        conn.options[:timeout] ||= DEFAULT_TIMEOUT
        conn.proxy   ||= proxy if proxy # we use ||= to keep proxy passed within options
        conn.headers = headers
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

    def headers
      {}.tap do |h|
        h.merge!(passed_headers) if passed_headers
        h['X-API-Version'] = version if version
      end
    end

    def logger
      (opts[:logger] || Logger.new(STDOUT)).tap { |l| l.level = Logger::INFO }
    end
  end
end
