require 'faraday'
require 'faraday_middleware'
require 'ostruct'
require 'be_gateway/version'
require 'backports/2.0.0/stdlib/ostruct'

module BeGateway
  autoload :Connection, "be_gateway/connection"
  autoload :Client, "be_gateway/client"
  autoload :AsyncClient, "be_gateway/async_client"
  autoload :Checkout, "be_gateway/checkout"
  autoload :Base, "be_gateway/response/base"
  autoload :Response, "be_gateway/response/response"
  autoload :ErrorResponse, "be_gateway/response/error_response"
  autoload :Transaction, "be_gateway/response/transaction"
  autoload :VerifyP2p, "be_gateway/response/verify_p2p"
  autoload :AsyncResponse, "be_gateway/response/async_response"
end
