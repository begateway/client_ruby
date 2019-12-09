module BeGateway
  class Base < OpenStruct
    attr_reader :code

    def initialize(response)
      @code = response.status
      @params = response.body

      super(response.body)
    end

    def to_params
      params.merge('code' => code)
    end

    private

    attr_reader :params

  end
end
