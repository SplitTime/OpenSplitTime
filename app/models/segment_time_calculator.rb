class SegmentTimeCalculator

  def self.typical_time(args)
    new(args).typical_time
  end

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:segment, :calc_model],
                           exclusive: [:segment, :effort_ids, :calc_model],
                           class: self.class)
    @segment = args[:segment]
    @effort_ids = args[:effort_ids]
    @calc_model = args[:calc_model]
    validate_setup
  end

  def typical_time
    case calc_model
    when :focused
      typical_time_by_stats(effort_ids)
    when :stats
      typical_time_by_stats
    else
      typical_time_by_terrain
    end
  end

  private

  attr_reader :segment, :effort_ids, :calc_model

  DISTANCE_FACTOR = 0.6 # Multiply distance in meters by this factor to approximate normal travel time on foot
  VERT_GAIN_FACTOR = 4.0 # Multiply vert_gain in meters by this factor to approximate normal travel time on foot
  STATS_CALC_THRESHOLD = 4

  def typical_time_by_terrain
    (segment.distance * DISTANCE_FACTOR) + (segment.vert_gain * VERT_GAIN_FACTOR)
  end

  def typical_time_by_stats(effort_ids = nil)
    return nil if effort_ids == []
    segment_time, effort_count = SplitTime.connection.execute(typical_time_sql(effort_ids)).values.flatten.map(&:to_i)
    effort_count > STATS_CALC_THRESHOLD ? segment_time : nil
  end

  def typical_time_sql(effort_ids)
    conn = ActiveRecord::Base.connection
    begin_id = conn.quote(segment.begin_id)
    begin_bitkey = conn.quote(segment.begin_bitkey)
    end_id = conn.quote(segment.end_id)
    end_bitkey = conn.quote(segment.end_bitkey)
    effort_id_list = conn.quote(effort_ids.join(','))[1..-2] if effort_ids # [1..-2] strips the resulting single quotes
    query = "SELECT AVG(st2.time_from_start - st1.time_from_start) AS segment_time, " +
        "COUNT(st1.time_from_start) AS effort_count " +
        "FROM (SELECT st.effort_id, st.time_from_start, st.split_id, st.sub_split_bitkey " +
        "FROM split_times st WHERE st.split_id = #{begin_id} AND st.sub_split_bitkey = #{begin_bitkey}) AS st1, " +
        "(SELECT st.effort_id, st.time_from_start, st.split_id, st.sub_split_bitkey " +
        "FROM split_times st WHERE st.split_id = #{end_id} AND st.sub_split_bitkey = #{end_bitkey}) AS st2 " +
        "WHERE st1.effort_id = st2.effort_id"
    query += " AND st1.effort_id IN (#{effort_id_list})" if effort_ids
    query
  end

  def validate_setup
    if calc_model == :focused && effort_ids.nil?
      raise ArgumentError, 'SegmentTimeCalculator cannot be initialized with calc_model: :focused unless effort_ids are provided'
    end
    if calc_model && SegmentTimesContainer::VALID_CALC_MODELS.exclude?(calc_model)
      raise ArgumentError, "calc_model #{calc_model} is not recognized"
    end
  end
end