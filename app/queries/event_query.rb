# frozen_string_literal: true

class EventQuery < BaseQuery
  def self.ordered_efforts_at_time_points(event_id)
    <<~SQL.squish
      with start_times as
        (select effort_id, absolute_time as start_time
        from split_times
           join efforts on efforts.id = split_times.effort_id
           join splits on splits.id = split_times.split_id
        where efforts.event_id = #{event_id} and split_times.lap = 1 and split_times.sub_split_bitkey = 1 and splits.kind = 0),

      elapsed_times as	
        (select lap, ast.split_id, ast.sub_split_bitkey, ast.effort_id, distance_from_start, ast.absolute_time - start_times.start_time as elapsed_time
        from split_times ast
           join efforts on efforts.id = ast.effort_id
           join splits on splits.id = ast.split_id
           join start_times on start_times.effort_id = ast.effort_id
        where efforts.event_id = #{event_id}
        order by lap, distance_from_start, sub_split_bitkey, elapsed_time)
        
      select lap, split_id, sub_split_bitkey, array_agg(effort_id) as effort_ids
      from elapsed_times
      group by lap, split_id, sub_split_bitkey, distance_from_start
      order by lap, distance_from_start, sub_split_bitkey
    SQL
  end
end
