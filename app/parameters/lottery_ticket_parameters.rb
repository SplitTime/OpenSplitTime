class LotteryTicketParameters < BaseParameters
  def self.permitted
    [
      :reference_number
    ]
  end
end
