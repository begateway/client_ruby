require "be_gateway/version"
require "backports/2.0.0/stdlib/ostruct"

module BeGateway
  autoload :Client, "be_gateway/client"
  autoload :Response, "be_gateway/response"
  autoload :ErrorResponse, "be_gateway/error_response"
  autoload :Transaction, "be_gateway/transaction"
end
