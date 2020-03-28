# frozen_string_literal: true

class TimePointWithEffortRank
  include ::ActiveModel::Model
  include ::ActiveModel::Attributes

  attribute :effort_id, :integer
  attribute :lap, :integer
  attribute :split_id, :integer
  attribute :sub_split_bitkey, :integer
  attribute :rank, :integer
  attribute :effort_ids_ahead, :integer_array_from_string

  def self.execute_query(effort)
    query = sql(effort)
    result = ::ActiveRecord::Base.connection.execute(query)
    result.map { |row| new(row) }
  end

  def self.sql(effort)
    effort_id = effort.id
    event_id = effort.event_id

    <<~SQL.squish
        with start_times as
            (select effort_id, absolute_time as start_time
             from split_times
                join efforts on efforts.id = split_times.effort_id
                join splits on splits.id = split_times.split_id
             where efforts.event_id = #{event_id} 
               and split_times.lap = 1 
               and split_times.sub_split_bitkey = #{SubSplit::IN_BITKEY} 
               and splits.kind = #{Split.kinds[:start]}),

          elapsed_times as
            (select lap, ast.split_id, ast.sub_split_bitkey, ast.effort_id, distance_from_start,
                    ast.absolute_time - start_times.start_time as elapsed_time
             from split_times ast
                join efforts on efforts.id = ast.effort_id
                join splits on splits.id = ast.split_id
                join start_times on start_times.effort_id = ast.effort_id
             where efforts.event_id = #{event_id}
             order by lap, distance_from_start, sub_split_bitkey, elapsed_time),
            
          ranking_subquery as
            (select effort_id, lap, split_id, sub_split_bitkey, distance_from_start,
                case when distance_from_start = 0 then null else
                     rank() over (partition by lap, distance_from_start, sub_split_bitkey 
                                  order by lap, distance_from_start, sub_split_bitkey, elapsed_time) end as rank,
                  case when distance_from_start = 0 then null else
                     array_agg(effort_id) over (partition by lap, distance_from_start, sub_split_bitkey 
                                                order by lap, distance_from_start, sub_split_bitkey, elapsed_time
                                                rows between unbounded preceding and 1 preceding) end as effort_ids_ahead
             from elapsed_times)

        select effort_id, lap, split_id, sub_split_bitkey, rank, effort_ids_ahead
        from ranking_subquery
        where effort_id = #{effort_id}
        order by lap, distance_from_start, sub_split_bitkey
    SQL
  end

  def time_point
    ::TimePoint.new(lap, split_id, sub_split_bitkey)
  end
end
