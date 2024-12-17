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

  # @return [Boolean]
  def finisher?
    division.name.include?("Finishers")
  end

  # @return [ActiveRecord::Relation<HistoricalFact>]
  def relevant_historical_facts
    historical_facts.where(kind: RELEVANT_KINDS).ordered_within_person
  end

  # @param [User] user
  # @return [Boolean]
  def service_manageable_by_user?(user)
    return false if user.nil?

    user.admin? || user.steward_of?(organization) || belongs_to_user?(user)
  end

  private

  # @param [User] user
  # @return [Boolean]
  def belongs_to_user?(user)
    lottery.entrants.belonging_to_user(user).include?(__getobj__)
  end
end
