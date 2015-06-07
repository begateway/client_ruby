require 'faraday'
require 'faraday_middleware'
require 'ostruct'
require 'be_gateway/version'
require 'backports/2.0.0/stdlib/ostruct'

module BeGateway
  autoload :Connection, "be_gateway/connection"
  autoload :Client, "be_gateway/client"
  autoload :Checkout, "be_gateway/checkout"
  autoload :Response, "be_gateway/response/response"
  autoload :ErrorResponse, "be_gateway/response/error_response"
  autoload :Transaction, "be_gateway/response/transaction"
end
