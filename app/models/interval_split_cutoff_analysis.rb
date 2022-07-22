# frozen_string_literal: true

class IntervalSplitCutoffAnalysis < ::ApplicationQuery
  attribute :end_seconds, :integer
  attribute :finished_count, :integer
  attribute :start_seconds, :integer
  attribute :total_count, :integer

  ROW_LIMIT = 300

  # @param [Integer] split_id
  # @param [Integer,ActiveSupport::Duration] band_width
  def self.execute_query(split_id:, band_width:)
    split = Split.find_by(id: split_id)
    return unless split.present?

    start_split_id = split.course.start_split.id
    band_width /= 1.second
    effort_segments = ::EffortSegment.where(begin_split_id: start_split_id, end_split_id: split_id)
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
  def self.sql(split_id:, band_width:)
    band_width /= 1.second

    <<~SQL.squish
      with
          course_splits as (
            select a.id, a.kind
            from splits s
            join splits a on a.course_id = s.course_id
            where s.id = #{split_id}
          ),

          subject_effort_segments as (
              select distinct on (effort_id, lap) effort_id, lap, elapsed_seconds
              from effort_segments
          where begin_split_id = (select id from course_splits where kind = 0)
            and end_split_id = #{split_id}
          order by effort_id, lap, end_bitkey desc
          ),
          
          finish_effort_segments as (
              select effort_id, lap, elapsed_seconds
              from effort_segments
          where begin_split_id = (select id from course_splits where kind = 0)
            and end_split_id = (select id from course_splits where kind = 1)
          ),
          
          all_effort_segments as (
              select ses.effort_id, ses.lap, ses.elapsed_seconds, fes.effort_id is not null as finished
              from subject_effort_segments ses
                  left join finish_effort_segments fes using (effort_id, lap)
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
             count(aes.effort_id) as total_count
      from all_effort_segments aes
        right join intervals i
          on aes.elapsed_seconds >= i.start_seconds and aes.elapsed_seconds < i.end_seconds
      where i.end_seconds is not null
      group by i.start_seconds, i.end_seconds
      order by i.start_seconds;
    SQL
  end
end
