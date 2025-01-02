class IntervalSplitCutoffAnalysis < ::ApplicationQuery
  attribute :start_seconds, :integer
  attribute :end_seconds, :integer
  attribute :finished_count, :integer
  attribute :stopped_here_count, :integer
  attribute :total_count, :integer

  ROW_LIMIT = 300

  # @param [Integer] split_id
  # @param [Integer,ActiveSupport::Duration] band_width
  def self.execute_query(split:, band_width:)
    start_split_id = split.course.start_split.id
    band_width /= 1.second
    effort_segments = ::EffortSegment.where(begin_split_id: start_split_id, end_split_id: split.id)
    max = effort_segments.maximum(:elapsed_seconds)
    min = effort_segments.minimum(:elapsed_seconds)
    return [] unless max.present? && min.present?

    time_span = max - min
    return if time_span / band_width > ROW_LIMIT

    super
  end

  # @param [Integer] split_id
  # @param [Integer,ActiveSupport::Duration] band_width
  # @return [String]
  def self.sql(split:, band_width:)
    band_width /= 1.second

    <<~SQL.squish
      with
          course_splits as (
            select a.id, a.kind
            from splits s
            join splits a on a.course_id = s.course_id
            where s.id = #{split.id}
          ),

          subject_effort_segments as (
              select distinct on (effort_id, lap) effort_id, lap, elapsed_seconds
              from effort_segments
          where begin_split_id = (select id from course_splits where kind = #{::Split.kinds[:start]})
            and end_split_id = #{split.id}
          order by effort_id, lap, end_bitkey desc
          ),
          
          finish_effort_segments as (
              select effort_id, lap, elapsed_seconds
              from effort_segments
          where begin_split_id = (select id from course_splits where kind = #{::Split.kinds[:start]})
            and end_split_id = (select id from course_splits where kind = #{::Split.kinds[:finish]})
          ),

          stopped_here_effort_ids as (
              select distinct st.effort_id, st.lap
              from split_times st
              where st.split_id = #{split.id}
                and st.stopped_here is true
          ),
          
          all_effort_segments as (
              select ses.effort_id, 
                     ses.lap, 
                     ses.elapsed_seconds, 
                     fes.effort_id is not null as finished, 
                     she.effort_id is not null as stopped_here
              from subject_effort_segments ses
                  left join finish_effort_segments fes using (effort_id, lap)
                  left join stopped_here_effort_ids she using (effort_id, lap)
          ),
          
          interval_starts as (
              select *
              from generate_series((select min(floor(elapsed_seconds / #{band_width}) * #{band_width}) from subject_effort_segments)::int,
                                   (select max(floor(elapsed_seconds / #{band_width}) * #{band_width}) + #{band_width} from subject_effort_segments)::int,
                                   #{band_width}) seconds
          ),

          intervals as (
              select seconds as start_seconds, lead(seconds) over(order by seconds) as end_seconds
              from interval_starts
          )
          
      select i.start_seconds,
             i.end_seconds,
             count(case when aes.finished is true then 1 else null end) as finished_count,
             count(case when aes.stopped_here is true then 1 else null end) as stopped_here_count,
             count(aes.effort_id) as total_count
      from all_effort_segments aes
        right join intervals i
          on aes.elapsed_seconds >= i.start_seconds and aes.elapsed_seconds < i.end_seconds
      where i.end_seconds is not null
      group by i.start_seconds, i.end_seconds
      order by i.start_seconds;
    SQL
  end

  def continued_dnf_count
    total_count - finished_count - stopped_here_count
  end
end
