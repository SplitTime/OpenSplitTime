class Lotteries::EntrantServiceDetailPresenter < SimpleDelegator
  def next_entrant_for_review
    return @next_entrant_for_review if defined?(@next_entrant_for_review)

    @next_entrant_for_review = lottery.entrants
      .pending_completed_form_review
      .where("lottery_entrants.id > ?", lottery_entrant_id)
      .order(id: :asc)
      .first
  end

  def previous_entrant_for_review
    return @previous_entrant_for_review if defined?(@previous_entrant_for_review)

    @previous_entrant_for_review = lottery.entrants
      .pending_completed_form_review
      .where("lottery_entrants.id < ?", lottery_entrant_id)
      .order(id: :desc)
      .first
  end
end
