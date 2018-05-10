# frozen_string_literal: true

class EventStageDisplay < EventWithEffortsPresenter

  attr_reader :associated_splits
  delegate :id, :unreconciled_efforts, :unreconciled_efforts?, :started?, :partners, :live_times, :multiple_sub_splits?, to: :event

  def post_initialize(args)
    @associated_splits ||= event.ordered_splits
  end

  def filtered_efforts
    @filtered_efforts ||= event_efforts
                              .includes(split_times: :split)
                              .search(search_text)
                              .where(filter_hash)
                              .order(sort_hash.presence || :bib_number)
                              .paginate(page: page, per_page: per_page)
  end

  def filtered_efforts_count
    filtered_efforts.total_entries
  end

  def course_splits
    course.splits
  end

  def course_splits_count
    course_splits.size
  end

  def filtered_live_times
    @filtered_live_times ||= live_times
                                 .includes(:split).includes(event: :aid_stations)
                                 .where(filter_hash)
                                 .order(sort_hash.presence || {created_at: :desc})
                                 .paginate(page: page, per_page: per_page)
  end

  def display_style
    %w(manage splits partners times).include?(params[:display_style]) ? params[:display_style] : 'times'
  end

  def concealed_text
    concealed? ? '(private)' : nil
  end

  private
end
