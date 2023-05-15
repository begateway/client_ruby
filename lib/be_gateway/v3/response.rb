module BeGateway
  module V3
    class Response
      attr_reader :status, :body, :code, :message, :friendly_message, :errors

      def initialize(status, body)
        @status = status
        @body = body.instance_of?(Hash) ? body : { 'body' => body }

        @code = @body['code']
        @message = @body['message']
        @friendly_message =  @body['friendly_message']
        @errors = @body['errors']
      end

      def successful?
        (200..299).cover?(status)
      end

      def failed?
        !successful?
      end
    end
  end
end
