# frozen_string_literal: true

class LotteryEntrantPresenter < SimpleDelegator
  RELEVANT_KINDS = [
    :dns,
    :dnf,
    :finished,
    :volunteer_year,
    :volunteer_year_major,
    :volunteer_multi,
  ].freeze

  def calculation
    lottery.ticket_calculations.find_by(person_id: person_id)
  end

  def relevant_historical_facts
    historical_facts.where(kind: RELEVANT_KINDS).ordered_within_person
  end

  def finisher?
    division.name.include?("Finishers")
  end

  private
end
