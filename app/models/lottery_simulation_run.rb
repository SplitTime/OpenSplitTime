# frozen_string_literal: true

class LotterySimulationRun < ApplicationRecord
  belongs_to :lottery
  has_many :simulations, class_name: "LotterySimulation", dependent: :destroy

  after_touch :broadcast_lottery_simulation_run

  scope :most_recent_first, -> { reorder(created_at: :desc) }

  enum status: {
    waiting: 0,
    processing: 1,
    finished: 2,
    failed: 3
  }

  validates_numericality_of :requested_count, greater_than: 0

  delegate :divisions, :organization, to: :lottery

  def parsed_errors
    JSON.parse(error_message || "[\"None\"]")
  end

  def set_context!
    context = divisions.map do |division|
      {
        division_name: division.name,
        entered: {
          male: division.entrants.male.count,
          female: division.entrants.female.count
        },
        pre_selected: {
          male: division.entrants.pre_selected.male.count,
          female: division.entrants.pre_selected.female.count
        },
      }
    end

    update_column(:context, context)
  end

  def set_elapsed_time!
    return unless persisted? && started_at.present?

    update_column(:elapsed_time, Time.current - started_at)
  end

  def start!
    update(started_at: ::Time.current)
  end

  private

  def broadcast_lottery_simulation_run
    broadcast_replace_to lottery, :lottery_simulation_runs, partial: "lottery_simulation_runs/lottery_simulation_run", locals: {organization: self.organization, lottery: self.lottery, lottery_simulation_run: self}
  end
end
