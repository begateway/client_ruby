module BeGateway
  class Transaction < OpenStruct
    def successful?
      self[:status] == "successful"
    end

    def incomplete?
      self[:status] == "incomplete"
    end

    def authorization
      return unless self[:authorization]

      @authorization ||= Authorization.new(self[:authorization])
    end

    def three_d_secure_verification
      return unless self[:three_d_secure_verification]

      @three_d_secure_verification ||= ThreeDSecureVerification.new(self[:three_d_secure_verification])
    end

    def max_mind_verification
      return unless self[:max_mind_verification]

      @max_mind_verification ||= MaxMindVerification.new(self[:max_mind_verification])
    end

    private

    attr_reader :params

    class Authorization < OpenStruct
    end

    class ThreeDSecureVerification < OpenStruct
    end

    class MaxMindVerification < OpenStruct
    end
  end
end
