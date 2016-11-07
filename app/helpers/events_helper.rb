module EventsHelper

  def suggested_match_id_hash(efforts)
    efforts.select(&:suggested_match).map { |effort| [effort.id, effort.suggested_match.id] }.to_h
  end

  def suggested_match_count(efforts)
    suggested_match_id_hash(efforts).count
  end

  def data_status(status_int)
    Effort.data_statuses.key(status_int)
  end

end
