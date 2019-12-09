module BeGateway
  class Base < OpenStruct
    attr_reader :code

    def initialize(response)
      @code = response.code
      @params = response.body

      super(response.body)
    end

    def to_params
      params
    end

    private

    attr_reader :params

  end
end
