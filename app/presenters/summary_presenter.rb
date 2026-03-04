class SummaryPresenter < EventWithEffortsPresenter
  def filtered_ranked_efforts
    return @filtered_ranked_efforts if defined?(@filtered_ranked_efforts)

    scope = ranked_efforts
      .finish_info_subquery
      .where(filter_hash)
      .where(finished: finished_filter)
      .search(search_text)

    @pagy, @filtered_ranked_efforts = pagy_from_scope(scope, limit: per_page, page: page)
    @filtered_ranked_efforts
  end

  def summary_title
    if finished_efforts_only?
      "Finishers"
    elsif unfinished_efforts_only?
      "Unfinished Entrants"
    else
      "All Entrants"
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
    if finished_efforts_only?
      [true]
    elsif unfinished_efforts_only?
      [false]
    else
      [true, false]
    end
  end
end
