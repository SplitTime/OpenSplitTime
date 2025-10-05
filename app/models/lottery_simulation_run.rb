class LotterySimulationRun < ApplicationRecord
  belongs_to :lottery
  has_many :simulations, class_name: "LotterySimulation", dependent: :destroy

  after_update :broadcast_lottery_simulation_run

  scope :most_recent_first, -> { reorder(created_at: :desc) }

  enum :status, {
    waiting: 0,
    processing: 1,
    finished: 2,
    failed: 3
  }

  validates_numericality_of :requested_count, greater_than: 0

  delegate :divisions, :organization, to: :lottery

  def division_percent(attr, *keys)
    keys = keys.map(&:to_s)
    numerator = division_sum(attr, *keys)
    return 0.0 if numerator == 0

    keys.pop
    child_keys = send(attr).values.first.dig(*keys).keys
    key_sets_for_denominator = child_keys.map { |child_key| keys + [child_key] }
    denominator = key_sets_for_denominator.sum { |set| division_sum(attr, *set) }
    return 0.0 if denominator == 0

    (numerator / denominator.to_f * 100).round(1)
  end

  def division_sum(attr, *keys)
    keys = keys.map(&:to_s)
    send(attr).sum { |_, division_values| division_values.dig(*keys) }
  end

  def single_division_percent(attr, division_name, *keys)
    keys = keys.map(&:to_s)
    numerator = single_division_sum(attr, division_name, *keys)
    return 0.0 if numerator == 0

    keys.pop
    child_keys = send(attr)[division_name].dig(*keys).keys
    key_sets_for_denominator = child_keys.map { |child_key| keys + [child_key] }
    denominator = key_sets_for_denominator.sum { |set| single_division_sum(attr, division_name, *set) }
    return 0.0 if denominator == 0

    (numerator / denominator.to_f * 100).round(1)
  end

  def single_division_sum(attr, division_name, *keys)
    send(attr)[division_name].dig(*keys)
  end

  def parsed_errors
    JSON.parse(error_message || "[]")
  end

  def set_context!
    context_array = divisions.ordered_by_name.map do |division|
      [
        division.name,
        {
          slots: {
            accepted: division.maximum_entries,
            wait_list: division.maximum_wait_list
          },
          entered: {
            male: division.entrants.male.count,
            female: division.entrants.female.count
          },
          pre_selected: {
            male: division.entrants.pre_selected.male.count,
            female: division.entrants.pre_selected.female.count
          },
        }
      ]
    end

    update(context: context_array.to_h)
  end

  def set_elapsed_time!
    return unless persisted? && started_at.present?

    update(elapsed_time: Time.current - started_at)
  end

  def start!
    update(started_at: ::Time.current)
  end

  def stats
    @stats ||=
      context.map do |division_name, _|
        male_accepted_average = simulations.map { |simulation| simulation.results.dig(division_name, "accepted", "male") }.average
        female_accepted_average = simulations.map { |simulation| simulation.results.dig(division_name, "accepted", "female") }.average
        male_wait_list_average = simulations.map { |simulation| simulation.results.dig(division_name, "wait_list", "male") }.average
        female_wait_list_average = simulations.map { |simulation| simulation.results.dig(division_name, "wait_list", "female") }.average

        [
          division_name,
          {
            "accepted" => {
              "male" => male_accepted_average.round(1),
              "female" => female_accepted_average.round(1),
            },
            "accepted_percent" => {
              "male" => (male_accepted_average / (male_accepted_average + female_accepted_average) * 100).round(1),
              "female" => (female_accepted_average / (male_accepted_average + female_accepted_average) * 100).round(1),
            },
            "wait_list" => {
              "male" => male_wait_list_average.round(1),
              "female" => female_wait_list_average.round(1),
            },
            "wait_list_percent" => {
              "male" => (male_wait_list_average / (male_wait_list_average + female_wait_list_average) * 100).round(1),
              "female" => (female_wait_list_average / (male_wait_list_average + female_wait_list_average) * 100).round(1),
            },
          }
        ]
      end.to_h
  end

  private

  def broadcast_lottery_simulation_run
    broadcast_replace_to lottery, :lottery_simulation_runs, partial: "lottery_simulation_runs/lottery_simulation_run", locals: {organization: self.organization, lottery: self.lottery, lottery_simulation_run: self}
  end
end
