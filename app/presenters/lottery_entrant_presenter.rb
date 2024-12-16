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

  # @return [Object, nil]
  def calculation
    return @calculation if defined?(@calculation)

    @calculation = if lottery.calculations_available? && person_id.present?
      lottery.ticket_calculations.find_by(person_id: person_id)
    else
      nil
    end
  end

  # @return [ActiveRecord::Relation<HistoricalFact>]
  def relevant_historical_facts
    historical_facts.where(kind: RELEVANT_KINDS).ordered_within_person
  end

  # @return [Boolean]
  def finisher?
    division.name.include?("Finishers")
  end
end
