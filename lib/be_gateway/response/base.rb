module BeGateway
  class Base < OpenStruct
    attr_reader :code

    def initialize(response)
      @code = response.status
      @params = response.body

      super(response.body)
    end

    def to_params
      response_params = params.dup
      response_params['api_code'] = response_params['code'] if response_params.key?('code')
      response_params['code'] = code
      response_params
    end

    private

    attr_reader :params

  end
end
