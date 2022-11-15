# frozen_string_literal: true

class LotteryDivisionParameters < BaseParameters
  def self.permitted
    [
      :maximum_entries,
      :maximum_wait_list,
      :name
    ]
  end
end
