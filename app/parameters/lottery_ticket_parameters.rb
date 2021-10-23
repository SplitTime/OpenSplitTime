# frozen_string_literal: true

class LotteryTicketParameters < BaseParameters
  def self.permitted
    [
      :reference_number,
    ]
  end
end
