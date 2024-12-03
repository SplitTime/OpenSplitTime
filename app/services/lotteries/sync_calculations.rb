# frozen_string_literal: true

class Lotteries::SyncCalculations
  def self.perform!(lottery)
    new(lottery).perform!
  end

  def initialize(lottery)
    @lottery = lottery
    @errors = []

    validate_setup
  end

  def perform!
    upsert_lottery_entrants
    delete_obsolete_entrants
  end

  private

  attr_reader :errors, :lottery
  delegate :calculation_class, :divisions, to: :lottery, private: true

  def upsert_lottery_entrants
    lottery_calculation.find_each do |calc|
      entrant = lottery.lottery_entrants.find_or_initialize_by(person_id: calc.person_id)

      entrant.assign_attributes(
        division: indexed_divisions[calc.division],
        first_name: calc.person.first_name,
        last_name: calc.person.last_name,
        gender: calc.person.gender,
        number_of_tickets: calc.ticket_count,
        birthdate: calc.person.birthdate,
        city: calc.person.city,
        state_code: calc.person.state_code,
        country_code: calc.person.country_code,
      # external_id: calc.external_id,
      # email: calc.person.email,
      # phone: calc.person.phone,
      )

      entrant.save!
    end
  end

  def delete_obsolete_entrants
    obsolete_person_ids = lottery_person_ids - calculation_person_ids
  end

  def indexed_divisions
    @indexed_divisions ||= divisions.index_by(&:name)
  end

  def calculated_division_names
    @calculated_divisions ||= lottery_calculation.group(:division).pluck(:division)
  end

  def lottery_calculation
    @lottery_calculation ||= lottery_calculation_class.where(organization: organization).includes(:person)
  end

  def lottery_calculation_class
    "Lotteries::Calculations::#{calculation_class}".safe_constantize
  end

  def obsolete_person_ids
    lottery_entrants.joins("")
  end

  def validate_setup
    non_existent_names = (calculated_division_names - indexed_divisions.keys)

    if non_existent_names.present?
      raise ArgumentError, "Calculated division names were not all found in the lottery: #{non_existent_names}"
    end
  end
end
