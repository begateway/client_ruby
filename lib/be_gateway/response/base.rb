module BeGateway
  class Base < OpenStruct
    def initialize(response)
      @params = response

      super(response)
    end
  end
end
