class Lotteries::DivisionPresenter < SimpleDelegator
  def initialize(division)
    raise ArgumentError, "division must be a LotteryDivision, #{division.class} was provided" unless division.is_a?(LotteryDivision)

    unless division.attributes.has_key?("tickets_drawn")
      division = LotteryDivision.with_progress_data.find_by(id: division.id)
    end

    super(division)
  end

  def accepted_tickets_drawn
    [maximum_entries, tickets_drawn].min
  end

  def waitlisted_tickets_drawn
    [maximum_wait_list, [(tickets_drawn - maximum_entries), 0].max].min
  end
end
