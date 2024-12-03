# frozen_string_literal: true

class Lotteries::CalculationsPresenter < LotteryPresenter
  CalculatedGroup = Struct.new(:name, :entrants_count, :tickets_count)

  delegate :calculation_class, to: :lottery

  def initialize(lottery, view_context)
    super
    validate_setup
  end

  def calculation_applicants_default_none
    lottery_calculation
      .joins(:person)
      .search_default_none(search_text)
  end

  def division_calculations
    @division_calculations ||=
      lottery_calculation.group(:division).pluck(Arel.sql("division, count(*), sum(ticket_count)")).map do |row|
        CalculatedGroup.new(*row)
      end
  end

  def division_entrants_count
    division_calculations.sum(&:entrants_count)
  end

  def division_tickets_count
    division_calculations.sum(&:tickets_count)
  end

  def gender_calculations
    @gender_calculations ||=
      lottery_calculation.group(:gender).pluck(Arel.sql("gender, count(*), sum(ticket_count)")).map do |row|
        CalculatedGroup.new(*row)
      end
  end

  def gender_entrants_count
    gender_calculations.sum(&:entrants_count)
  end

  def gender_tickets_count
    gender_calculations.sum(&:tickets_count)
  end

  private

  def calculated_division_names
    @calculated_divisions ||= lottery_calculation.group(:division).pluck(:division)
  end

  def lottery_calculation
    @lottery_calculation ||= lottery_calculation_class.where(organization: organization)
  end

  def lottery_calculation_class
    "Lotteries::Calculations::#{calculation_class}".safe_constantize
  end

  def validate_setup
    raise "Lottery must have an assigned calculation_class" unless calculation_class.present?
    raise "Lottery calculation class does not exist" unless lottery_calculation_class.present?
  end
end
