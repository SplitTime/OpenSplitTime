class PlaceDetailRow

  attr_reader :split_times, :split_place_in, :split_place_out, :passed_segment, :passed_in_aid,
              :passed_by_segment, :passed_by_in_aid, :together_in_aid
  delegate :base_name, :distance_from_start, to: :split

  # split_times should be an array having size == split.sub_split_bitkey_hashes.size,
  # with nil values where no corresponding split_time exists

  def initialize(effort, split, previous_split, split_times, places, efforts)
    @effort = effort
    @split = split
    @previous_split = previous_split
    @split_times = split_times
    @split_place_in = places[:split_place_in]
    @split_place_out = places[:split_place_out]
    @passed_segment = efforts[:passed_segment]
    @passed_in_aid = efforts[:passed_in_aid]
    @passed_by_segment = efforts[:passed_by_segment]
    @passed_by_in_aid = efforts[:passed_by_in_aid]
    @together_in_aid = efforts[:together_in_aid]
  end

  def days_and_times
    split_times.map { |split_time| split_time ? split_time.day_and_time_attr : nil }
  end

  def end_bitkey_hash
    split_times.last.present? ? split_times.last.bitkey_hash : nil
  end

  def passed_segment_count
    passed_segment ? passed_segment.count : nil
  end
  
  def passed_in_aid_count
    passed_in_aid ? passed_in_aid.count : nil
  end

  def passed_by_segment_count
    passed_by_segment ? passed_by_segment.count : nil
  end

  def passed_by_in_aid_count
    passed_by_in_aid ? passed_by_in_aid.count : nil
  end

  def together_in_aid_count
    together_in_aid ? together_in_aid.count : nil
  end

  def passed_segment_ids
    passed_segment ? passed_segment.map(&:id) : nil
  end

  def passed_in_aid_ids
    passed_in_aid ? passed_in_aid.map(&:id) : nil
  end

  def passed_by_segment_ids
    passed_by_segment ? passed_by_segment.map(&:id) : nil
  end

  def passed_by_in_aid_ids
    passed_by_in_aid ? passed_by_in_aid.map(&:id) : nil
  end

  def together_in_aid_ids
    together_in_aid ? together_in_aid.map(&:id) : nil
  end

  def passed_segment_table_title
    "#{effort_name} passed #{persons(passed_segment_count)} between #{previous_split.base_name} and #{split.base_name}"
  end

  def passed_in_aid_table_title
    "#{effort_name} passed #{persons(passed_in_aid_count)} in aid at #{split.base_name}"
  end

  def passed_by_segment_table_title
    "#{effort_name} was passed by #{persons(passed_by_segment_count)} between #{previous_split.base_name} and #{split.base_name}"
  end

  def passed_by_in_aid_table_title
    "#{effort_name} was passed by #{persons(passed_by_in_aid_count)} while in aid at #{split.base_name}"
  end

  def together_in_aid_table_title
    "#{effort_name} was in #{split.base_name} with #{persons(together_in_aid_count)}"
  end

  def persons(number)
    number == 1 ? "#{number} person" : "#{number} people"
  end

  def split_id
    split.id
  end

  private

  attr_reader :effort, :split, :previous_split

  def effort_name
    effort.full_name
  end

end