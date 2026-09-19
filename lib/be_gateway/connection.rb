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

      if request_logger
        request_logger.info { "[beGateway client response] Status: #{r.status} Headers: #{r.headers}" }
        request_logger.debug { "[beGateway client response] Body: #{r.body}" }
      end

      build_response(r)
    rescue StandardError, Faraday::ClientError => e
      request_logger.error("Connection error to '#{path}': [#{e.class}] #{e.message} \n #{e.backtrace}") if request_logger

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
      @connection ||= Faraday::Connection.new(url, opts.except(:logger)) do |conn|
        conn.options[:open_timeout] ||= DEFAULT_OPEN_TIMEOUT
        conn.options[:timeout] ||= DEFAULT_TIMEOUT
        conn.proxy   ||= proxy if proxy # we use ||= to keep proxy passed within options
        conn.headers = headers
        conn.request :json
        conn.request :basic_auth, login, password
        conn.response :json
        if request_logger
          conn.response :logger, request_logger, headers: true, bodies: false do |formatter|
            formatter.filter(/(Authorization: "?Basic )[^"\s]+/, '\1[FILTERED]')
          end
        end
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
      (passed_headers || {}).tap do |h|
        h['X-API-Version'] = version.to_s if version
      end
    end

    def request_logger
      opts[:logger] || logger
    end
  end
end
