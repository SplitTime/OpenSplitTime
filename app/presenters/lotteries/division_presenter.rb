class Lotteries::DivisionPresenter < SimpleDelegator
  def initialize(division)
    raise ArgumentError, "division must be a LotteryDivision, #{division.class} was provided" unless division.is_a?(LotteryDivision)

    unless division.attributes.has_key?("drawn_tickets_count")
      division = LotteryDivision.with_drawn_tickets_count.find_by(id: division.id)
    end

    super(division)
  end

  def accepted_drawn_tickets_count
    [maximum_entries, drawn_tickets_count].min
  end

  def waitlisted_drawn_tickets_count
    [maximum_wait_list, [(drawn_tickets_count - maximum_entries), 0].max].min
  end
end
