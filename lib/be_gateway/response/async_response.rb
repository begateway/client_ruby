module BeGateway
  class AsyncResponse < OpenStruct
    attr_reader :status, :body

    def initialize(response)
      @status = response.status
      @body = response.body
    end

    def success?
      (200..299).cover?(status)
    end
  end
end
