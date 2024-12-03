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

  def relevant_historical_facts
    historical_facts.where(kind: RELEVANT_KINDS).ordered_within_person
  end

  def ticket_calc_description
    result = dns_text_component
  end

  def finisher?
    division.name.include?("Finishers")
  end

  private

  def finishers_formula_description
    <<~TEXT
    TEXT
  end

  def nevers_formula_description
    <<~TEXT
      You are in a Nevers lottery. Your exponent is calculated as follows:

      Number of DNS since your last start
      Plus years of volunteering at Hardrock / 5 (rounded down)
      Plus one-time service tickets for trail work, shown here as "VMajor"

      Your tickets are equal to 2 to the power of your exponent component. 
      For example, if your exponent component is 3, then your ticket count is 2 ^ 3 = 8.
      If your exponent component is 0, then your ticket count is 2 ^ 0 = 1.
    TEXT
  end
end
