# frozen_string_literal: true

class SummaryPresenter < EventWithEffortsPresenter

  def filtered_ranked_efforts
    @filtered_ranked_efforts ||=
        ranked_efforts
            .select { |effort| filtered_ids.include?(effort.id) }
            .select { |effort| finished_filter.include?(effort.finished) }
            .paginate(page: page, per_page: per_page)
  end

  def summary_title
    case
    when finished_efforts_only?
      'Finishers'
    when unfinished_efforts_only?
      'Unfinished Entrants'
    else
      'All Entrants'
    end
  end

  def finished_efforts_only?
    params[:finished]&.to_boolean == true
  end

  def unfinished_efforts_only?
    params[:finished]&.to_boolean == false
  end

  def all_efforts?
    !finished_efforts_only? && !unfinished_efforts_only?
  end

  private

  def finished_filter
    case
    when finished_efforts_only?
      [true]
    when unfinished_efforts_only?
      [false]
    else
      [true, false]
    end
  end
end
