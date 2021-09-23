module BeGateway
  class AsyncResponse
    attr_reader :status, :body

    def initialize(response)
      @status = response.status
      @body = response.body
    end

    def successful?
      (200..299).cover?(status)
    end

    def failed?
      !successful? && !processing?
    end

    def processing?
      body.dig('status') == 'processing'
    end
  end
end
