module BeGateway
  class ErrorResponse < Base
    def status
      'error'
    end

    def invalid?
      true
    end

    def errors
      @errors ||= Errors.new(self['response']['errors'])
    end

    def message
      @message ||= self['response']['message']
    end

    def async_status
      params["status"]
    end

    private

    class Errors < OpenStruct
      def attributes
        each_pair.collect {|attr, _| attr }
      end

      def on(attribute)
        self[attribute]
      end

      def for(attribute)
        Errors.new(self[attribute])
      end
    end
  end
end
