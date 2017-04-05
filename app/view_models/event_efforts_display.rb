class EventEffortsDisplay < EventWithEffortsPresenter

  def filtered_unstarted_efforts
    @filtered_unstarted_efforts ||=
        unstarted_efforts
            .order(params[:sort])
            .search(params[:search])
            .paginate(page: params[:unstarted_page], per_page: params[:per_page] || 25)
  end

  def filtered_unstarted_efforts_count
    filtered_unstarted_efforts.total_entries
  end

end
