# frozen_string_literal: true

class PlaceDetailRow
  CATEGORIES = [:passed_segment, :passed_in_aid, :passed_by_segment, :passed_by_in_aid, :together_in_aid]

  attr_reader :split_times
  delegate :distance_from_start, to: :lap_split

  # split_times should be an array having size == lap_split.time_points.size,
  # with nil values where no corresponding split_time exists

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:lap_split, :split_times],
                           exclusive: [:lap_split, :split_times, :previous_lap_split, :show_laps,
                                       :effort_name, :effort_ids_by_category],
                           class: self.class)
    @lap_split = args[:lap_split]
    @split_times = args[:split_times] || []
    @previous_lap_split = args[:previous_lap_split]
    @show_laps = args[:show_laps]
    @effort_name = args[:effort_name]
    @effort_ids_by_category = args[:effort_ids_by_category]
  end

  def name
    show_laps? ? name_with_lap : name_without_lap
  end

  def absolute_times_local
    split_times.map { |st| st.absolute_time_local if st }
  end

  def end_time_point
    split_times.last&.time_point
  end

  def encountered_ids # Preserve duplicates to ensure accurate frequency testing
    (passed_segment_ids + passed_by_segment_ids + together_in_aid_ids)
  end

  CATEGORIES.each do |category|
    define_method("#{category}_ids") do
      effort_ids_by_category[category]
    end
  end

  CATEGORIES.each do |category|
    define_method("#{category}_table_title") do
      table_titles_by_category[category]
    end
  end

  private

  attr_reader :lap_split, :previous_lap_split, :show_laps, :effort_name, :effort_ids_by_category

  def persons(number)
    "#{number} person".pluralize(number)
  end

  def table_titles_by_category
    {passed_segment: "#{effort_name} passed #{persons(passed_segment_ids.size)} between" +
        " #{split_base_name(previous_lap_split)} and #{split_base_name(lap_split)}",
     passed_in_aid: "#{effort_name} passed #{persons(passed_in_aid_ids.size)} in aid at #{split_base_name(lap_split)}",
     passed_by_segment: "#{effort_name} was passed by #{persons(passed_by_segment_ids.size)} between " +
         "#{split_base_name(previous_lap_split)} and #{split_base_name(lap_split)}",
     passed_by_in_aid: "#{effort_name} was passed by #{persons(passed_by_in_aid_ids.size)} while in aid at " +
         "#{split_base_name(lap_split)}",
     together_in_aid: "#{effort_name} was in #{split_base_name(lap_split)} with #{persons(together_in_aid_ids.size)}"}
  end

  def show_laps?
    @show_laps
  end
  
  def split_base_name(lap_split)
    show_laps? ? lap_split.base_name : lap_split.base_name_without_lap
  end

  def name_without_lap
    lap_split.name_without_lap
  end

  def name_with_lap
    lap_split.name
  end
end
