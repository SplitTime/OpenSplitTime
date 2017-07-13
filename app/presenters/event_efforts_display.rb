class EventEffortsDisplay < EventWithEffortsPresenter

  def filtered_unstarted_efforts
    @filtered_unstarted_efforts ||=
        unstarted_efforts
            .order(sort_hash)
            .where(filter_hash)
            .search(search_text)
            .paginate(page: unstarted_page, per_page: per_page)
  end

  def unstarted_page
    params[:unstarted_page]
  end

  def filtered_unstarted_efforts_count
    filtered_unstarted_efforts.total_entries
  end

  def cache_key_started
    cache_key('started')
  end

  def cache_key_unstarted
    cache_key('unstarted')
  end

  def cache_key(tag)
    "#{to_param}/#{Rails.env}/#{tag}/page[number]=#{send("#{tag}_page")}&page[size]=#{per_page}&search=#{search_text}&sort=#{sort_string}&filter=#{filter_hash}"
  end
end
