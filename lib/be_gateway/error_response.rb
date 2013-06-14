module BeGateway
  class ErrorResponse < OpenStruct
    def initialize(response)
      super(response)
    end

    def invalid?
      true
    end
    
    def transaction_type
      transaction["type"]
    end

    def errors
      @errors ||= Errors.new(self[:errors])
    end

    private

    attr_reader :params

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
