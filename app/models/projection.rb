# frozen_string_literal: true

class Projection
  include ::ActiveModel::Model
  include ::ActiveModel::Attributes

  NULL_QUERY = "select * from generate_series(0, -1) x;"

  attribute :lap, :integer
  attribute :split_id, :integer
  attribute :sub_split_bitkey, :integer
  attribute :effort_count, :integer
  attribute :effort_years, :integer_array_from_string
  attribute :low_ratio, :float
  attribute :average_ratio, :float
  attribute :high_ratio, :float
  attribute :low_seconds, :integer
  attribute :average_seconds, :integer
  attribute :high_seconds, :integer

  alias_attribute :bitkey, :sub_split_bitkey

  def self.execute_query(*args)
    query = sql(*args)
    result = ::ActiveRecord::Base.connection.execute(query)
    result.map { |row| new(row) }
  end

  def self.sql(split_time, starting_time_point, subject_time_points)
    unless split_time && starting_time_point && subject_time_points
      raise ArgumentError, 'Projection.sql requires a split_time, starting_time_point, and subject_time_points'
    end

    completed_lap, completed_split_id, completed_bitkey = split_time.time_point.values
    starting_lap, starting_split_id, starting_bitkey = starting_time_point.values
    completed_seconds = split_time.time_from_start

    return NULL_QUERY if completed_seconds == 0 || subject_time_points.empty?

    projected_where_array = subject_time_points.map do |tp|
      "(lap = #{tp.lap} and split_id = #{tp.split_id} and sub_split_bitkey = #{tp.bitkey})"
    end
    projected_where_clause = projected_where_array.join(' or ').presence || 'true'

    overall_limit = 100
    similarity_threshold = 0.3

    <<~SQL.squish
      with 
        completed_split_times as
          (select cst.effort_id, 
              cst.absolute_time,
              extract(epoch from(cst.absolute_time - sst.absolute_time)) as completed_segment_seconds,
              abs(extract(epoch from(cst.absolute_time - sst.absolute_time)) - #{completed_seconds}) as difference
          from split_times cst
            inner join split_times sst 
                    on sst.effort_id = cst.effort_id 
                   and sst.lap = #{starting_lap}
                   and sst.split_id = #{starting_split_id}
                   and sst.sub_split_bitkey = #{starting_bitkey}
          where cst.lap = #{completed_lap}
            and cst.split_id = #{completed_split_id}
            and cst.sub_split_bitkey = #{completed_bitkey}
          order by difference
          limit #{overall_limit}),

        main_subquery as
          (select pst.effort_id, 
              lap,
              split_id,
              sub_split_bitkey,
              completed_segment_seconds,
              extract(year from (pst.absolute_time)) as effort_year,
              extract(epoch from(pst.absolute_time - cst.absolute_time)) as projected_segment_seconds
          from completed_split_times cst
            inner join split_times pst on pst.effort_id = cst.effort_id
          where (#{projected_where_clause})
            and difference / #{completed_seconds} < #{similarity_threshold}),

        ratio_subquery as
          (select *,
              case when completed_segment_seconds = 0 
                   then null 
                   else round((projected_segment_seconds / completed_segment_seconds)::numeric, 6) end as ratio
          from main_subquery),
          
        order_count_subquery as
          (select *,
              row_number() over (partition by lap, split_id, sub_split_bitkey order by ratio) as row_number,
              sum(1) over (partition by lap, split_id, sub_split_bitkey) as total
          from ratio_subquery),
          
        quartiles as
            (select lap, 
                split_id, 
                sub_split_bitkey,
                effort_year,
                ratio,
                avg(case when row_number >= (floor(total/2.0)/2.0)
                      and row_number <= (floor(total/2.0)/2.0) + 1
                     then ratio else null end) 
                  over (partition by lap, split_id, sub_split_bitkey) as q1,
                avg(case when row_number >= (total/2.0)
                      and row_number <= (total/2.0) + 1
                     then ratio else null end)
                  over (partition by lap, split_id, sub_split_bitkey) as median,
                avg(case when row_number >= (ceil(total/2.0) + (floor(total/2.0)/2.0))
                      and row_number <= (ceil(total/2.0) + (floor(total/2.0)/2.0) + 1)
                     then ratio else null end)
                  over (partition by lap, split_id, sub_split_bitkey) as q3
            from order_count_subquery),
              
        bounds as
          (select *,
              q3 - q1 as iqr,
              q1 - ((q3 - q1) * 1.5) as lower_bound,
              q3 + ((q3 - q1) * 1.5) as upper_bound
          from quartiles),
              
        valid_ratios as
          (select *
          from bounds
          where ratio between lower_bound and upper_bound),

        stats_subquery as
          (select lap, 
              split_id, 
              sub_split_bitkey,
      				array_to_string(array_agg(distinct effort_year), ',') as effort_years,
              count(ratio) as effort_count,
              round(avg(ratio), 6) as average,
              round(stddev(ratio) * 2, 6) as std2
          from valid_ratios
          group by lap, split_id, sub_split_bitkey),
      
        final_subquery as
          (select lap, 
              split_id, 
              sub_split_bitkey,
              effort_count,
              effort_years,
              case when average >= 0 and (average - std2) is not null
                   then greatest(0, average - std2) 
                   else average - std2 end as low_ratio,
              average as average_ratio,
              average + std2 as high_ratio
          from stats_subquery)
          
      select final_subquery.*, 
          round(low_ratio * #{completed_seconds})::int as low_seconds,
          round(average_ratio * #{completed_seconds})::int as average_seconds,
          round(high_ratio * #{completed_seconds})::int as high_seconds
      from final_subquery
        inner join splits on splits.id = split_id
      order by lap, distance_from_start, sub_split_bitkey
    SQL
  end

  def time_point
    TimePoint.new(lap, split_id, bitkey)
  end
end
