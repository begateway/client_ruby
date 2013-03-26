require "be_gateway/version"

module BeGateway
  autoload :Client, "be_gateway/client"
  autoload :Response, "be_gateway/response"
  autoload :ErrorResponse, "be_gateway/error_response"
  autoload :Transaction, "be_gateway/transaction"
end
