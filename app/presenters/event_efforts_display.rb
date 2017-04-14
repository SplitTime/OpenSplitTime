class EventEffortsDisplay < EventWithEffortsPresenter

  def filtered_unstarted_efforts
    @filtered_unstarted_efforts ||=
        unstarted_efforts
            .order(sort_hash)
            .where(filter_hash)
            .search(search_text)
            .paginate(page: params[:unstarted_page], per_page: per_page)
  end

  def filtered_unstarted_efforts_count
    filtered_unstarted_efforts.total_entries
  end
end
