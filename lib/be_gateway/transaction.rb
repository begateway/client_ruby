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

      @authorization ||= Section.new(self[:authorization])
    end

    def payment
      return unless self[:payment]

      @payment ||= Section.new(self[:payment])
    end

    def refund
      return unless self[:refund]

      @refund ||= Section.new(self[:refund])
    end

    def three_d_secure_verification
      return unless self[:three_d_secure_verification]

      @three_d_secure_verification ||= Section.new(self[:three_d_secure_verification])
    end

    def max_mind_verification
      return unless self[:max_mind_verification]

      @max_mind_verification ||= Section.new(self[:max_mind_verification])
    end

    private

    attr_reader :params

    class Section < OpenStruct
    end
  end
end
