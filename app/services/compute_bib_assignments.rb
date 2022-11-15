# frozen_string_literal: true

class ComputeBibAssignments
  # @param [::Event] event
  # @param [String,Symbol] strategy
  # @return [Hash]
  def self.perform(event, strategy)
    new(event, strategy).perform
  end

  # @param [::Event] event
  # @param [String,Symbol] strategy
  def initialize(event, strategy)
    @event = event
    @strategy = strategy
    @result = {}
  end

  # @return [Hash]
  def perform
    return unless strategy.present?

    case strategy.to_sym
    when :hardrock
      compute_for_hardrock
    else
      raise ArgumentError, "Unknown bib assignment strategy"
    end

    result
  end

  private

  attr_reader :event, :strategy, :result

  def compute_for_hardrock
    efforts = event.efforts.select(:id, :person_id, :first_name, :last_name).to_a
    prior_hardrock = event.organization.events.where("scheduled_start_time < ?", event.scheduled_start_time).order(scheduled_start_time: :desc).first
    ordered_prior_person_ids = prior_hardrock.efforts.finished.ranked_order.pluck(:person_id)

    current_bib = 1
    ordered_prior_person_ids.each do |person_id|
      matching_effort = efforts.find { |effort| effort.person_id == person_id }
      next unless matching_effort.present?

      efforts.delete(matching_effort)
      result[matching_effort.id] = current_bib
      current_bib += 1
    end

    efforts.sort_by { |effort| [effort.last_name, effort.first_name] }.each.with_index(100) do |effort, index|
      result[effort.id] = index
    end
  end
end
