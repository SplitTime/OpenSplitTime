class EffortAutoReconciler
  def initialize(event)
    @event = event
    @unreconciled_efforts = event.unreconciled_efforts.to_a
    @auto_matched_count = EventReconcileService.assign_participants_to_efforts(matched_hash)
    @auto_created_count = EventReconcileService.create_participants_from_efforts(not_matched_array)
  end

  def report
    [matched_report, created_report, unreconciled_report].join
  end

  private

  attr_reader :event, :unreconciled_efforts, :auto_matched_count, :auto_created_count

  def matched_hash
    @matched_hash ||= exact_matches.map { |effort, participant| [effort.id, participant.id] }.to_h
  end

  def not_matched_array
    @not_matched_array ||= not_matched_efforts.map(&:id)
  end

  def exact_matches
    @exact_matches ||= unreconciled_efforts
                           .map { |effort| [effort, effort.exact_matching_participant] }
                           .select { |_, participant| participant }.to_h
  end

  def close_matches
    @close_matches ||= unreconciled_efforts
                           .map { |effort| [effort, effort.suggest_close_match] }
                           .select { |_, participant| participant }
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
    close_matched_efforts.count
  end

  def matched_report
    auto_matched_count > 0 ?
        "We found #{auto_matched_count} participants that matched our database. " :
        'No participants matched our database exactly. '
  end

  def created_report
    auto_created_count > 0 ?
        "We created #{auto_created_count} participants from efforts that had no close matches. " :
        ''
  end

  def unreconciled_report
    close_matched_count > 0 ?
        "We found #{close_matched_count} participants that may or may not match our database. Please reconcile them now. " :
        "All efforts for #{event.name} have been reconciled. "
  end
end