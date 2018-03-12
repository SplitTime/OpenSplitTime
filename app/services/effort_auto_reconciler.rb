# frozen_string_literal: true

class EffortAutoReconciler

  def self.reconcile(event, options = {})
    reconciler = new(event, options)
    reconciler.reconcile
    reconciler.report
  end

  def initialize(event, options = {})
    @event = event
    @background_channel = options[:background_channel]
    @unreconciled_efforts = event.unreconciled_efforts.to_a
  end

  def reconcile
    assign_response = Interactors::AssignPeopleToEfforts.perform!(matched_hash)
    self.auto_matched_count = assign_response.resources[:saved].size
    create_response = Interactors::CreatePeopleFromEfforts.perform!(not_matched_array)
    self.auto_created_count = create_response.resources[:saved].size
  end

  def report
    [matched_report, created_report, unreconciled_report].join
  end

  private

  attr_reader :event, :background_channel, :unreconciled_efforts
  attr_accessor :auto_matched_count, :auto_created_count

  def matched_hash
    @matched_hash ||= exact_matches.map { |effort, person| [effort.id, person.id] }.to_h
  end

  def not_matched_array
    @not_matched_array ||= not_matched_efforts.map(&:id)
  end

  def exact_matches
    @exact_matches ||= unreconciled_efforts
                           .map { |effort| [effort, effort.exact_matching_person] }.to_h.compact
  end

  def close_matches
    @close_matches ||= unreconciled_efforts
                           .map { |effort| [effort, effort.suggest_close_match] }
                           .select { |_, person| person }
                           .reject { |effort, _| exact_matched_efforts.include?(effort) }.to_h
  end

  def exact_matched_efforts
    @exact_matched_efforts ||= exact_matches.keys
  end

  def close_matched_efforts
    @close_matched_efforts ||= close_matches.keys
  end

  def not_matched_efforts
    @not_matched_efforts ||= unreconciled_efforts - exact_matched_efforts - close_matched_efforts
  end

  def close_matched_count
    close_matched_efforts.size
  end

  def matched_report
    auto_matched_count > 0 ?
        "We found #{auto_matched_count} people that matched our database. " :
        'No people matched our database exactly. '
  end

  def created_report
    auto_created_count > 0 ?
        "We created #{auto_created_count} people from efforts that had no close matches. " :
        ''
  end

  def unreconciled_report
    close_matched_count > 0 ?
        "We found #{close_matched_count} people that may or may not match our database. Please reconcile them now. " :
        "All efforts for #{event.name} have been reconciled. "
  end
end
