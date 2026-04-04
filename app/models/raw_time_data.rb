# This Struct is a lightweight alternative to RawTime when many objects are needed.

RawTimeData = Struct.new(
  :id,
  :event_group_id,
  :bib_number,
  :split_name,
  :bitkey,
  :stopped_here,
  :data_status_numeric,
  :entered_time,
  :absolute_time_string,
  :absolute_time_local_string,
  :source,
  :created_by,
  :reviewed_by,
  keyword_init: true # rubocop:disable Style/RedundantStructKeywordInit
) do
  include SourceTextable

  def absolute_time
    absolute_time_string&.to_datetime
  end

  def absolute_time_local
    absolute_time_local_string&.to_datetime
  end

  def military_time
    if absolute_time_local_string.present?
      absolute_time_local_string.split.last
    else
      TimeConversion.user_entered_to_military(entered_time)
    end
  end

  def data_status
    RawTime.data_statuses.invert[data_status_numeric]
  end

  def stopped_here?
    stopped_here
  end
end
