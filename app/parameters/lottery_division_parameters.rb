class LotteryDivisionParameters < BaseParameters
  def self.permitted
    [
      :maximum_entries,
      :maximum_wait_list,
      :name
    ]
  end
end
