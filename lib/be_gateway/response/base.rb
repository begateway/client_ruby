module BeGateway
  class Base < OpenStruct
    def initialize(response)
      @params = response

      super(response)
    end

    def to_params
      params
    end

    private

    attr_reader :params

  end
end
