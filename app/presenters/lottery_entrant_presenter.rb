class LotteryEntrantPresenter < SimpleDelegator
  RELEVANT_KINDS = [
    :dns,
    :dnf,
    :finished,
    :volunteer_year,
    :volunteer_year_major,
    :volunteer_multi,
    :lottery_application,
    :volunteer_points,
    :trail_work_hours,
    :ticket_reset_legacy,
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

  # @return [Boolean]
  def ticket_calculation_partial_renderable?
    calculation.present? && calculation_table_present?
  end

  # @return [String, nil]
  def ticket_calculation_partial_name
    return if lottery.calculation_class.nil?

    "lottery_entrants/ticket_calculation_tables/#{lottery.calculation_class.underscore}"
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

  # @return [Array<Integer>]
  def ticket_reference_numbers
    @ticket_reference_numbers ||= tickets.pluck(:reference_number)
  end

  private

  # @return [Boolean]
  def calculation_table_present?
    partial_path.present? && File.exist?(partial_path)
  end

  # @return [Path, nil]
  def partial_path
    return if lottery.calculation_class.nil?

    Rails.root.join("app", "views", "lottery_entrants", "ticket_calculation_tables", "_#{lottery.calculation_class.underscore}.html.erb")
  end

  # @param [User] user
  # @return [Boolean]
  def belongs_to_user?(user)
    lottery.entrants.belonging_to_user(user).include?(__getobj__)
  end
end
