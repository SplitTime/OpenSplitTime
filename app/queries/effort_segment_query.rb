# frozen_string_literal: true

class EffortSegmentQuery < BaseQuery
  def self.set_for_effort(effort)
    set(effort.id)
  end

  def self.set_for_split_time(split_time)
    set(split_time.effort_id, split_time.lap, split_time.split_id, split_time.bitkey)
  end

  def self.set(effort_id, lap = nil, split_id = nil, bitkey = nil)
    scoping_sql =
      if lap.nil? || split_id.nil? || bitkey.nil?
        # Update all effort_segments for the entire effort
        ""
      else
        # Update only the effort_segments relevant to the split time
        "and ((ss1.lap = #{lap} and ss1.split_id = #{split_id} and ss1.sub_split_bitkey = #{bitkey})" +
          "or (ss2.lap = #{lap} and ss2.split_id = #{split_id} and ss2.sub_split_bitkey = #{bitkey}))"
      end

    <<~SQL.squish
      with sub_splits as
               (select course_id,
                       effort_id,
                       lap,
                       split_id,
                       sub_split_bitkey,
                       distance_from_start,
                       absolute_time,
                       elapsed_seconds
                from split_times
                         join splits on splits.id = split_times.split_id
                where split_times.effort_id = #{effort_id}),

           sub_split_segments as
               (select ss1.course_id,
                       ss1.split_id                              as begin_split_id,
                       ss1.sub_split_bitkey                      as begin_bitkey,
                       ss2.split_id                              as end_split_id,
                       ss2.sub_split_bitkey                      as end_bitkey,
                       ss1.effort_id,
                       ss1.lap,
                       ss1.absolute_time                         as begin_time,
                       ss2.absolute_time                         as end_time,
                       ss2.elapsed_seconds - ss1.elapsed_seconds as elapsed_seconds
                from sub_splits ss1
                         cross join sub_splits ss2
                where ss1.lap = ss2.lap
                  #{scoping_sql}
                  and ((ss1.distance_from_start = ss2.distance_from_start and ss1.sub_split_bitkey < ss2.sub_split_bitkey)
                    or (ss1.distance_from_start < ss2.distance_from_start)))

      insert
      into effort_segments
              (select * from sub_split_segments)
      on conflict (begin_split_id, begin_bitkey, end_split_id, end_bitkey, effort_id, lap) do update
          set begin_time      = EXCLUDED.begin_time,
              end_time        = EXCLUDED.end_time,
              elapsed_seconds = EXCLUDED.elapsed_seconds,
              data_status     = null;
    SQL
  end

  def self.destroy_for_effort(effort)
    <<~SQL.squish
      delete
      from effort_segments
      where effort_id = #{effort.id}
    SQL
  end

  def self.destroy_for_split_time(split_time)
    effort_id = split_time.effort_id
    lap = split_time.lap
    split_id = split_time.split_id
    bitkey = split_time.bitkey

    <<~SQL.squish
      delete
      from effort_segments
      where effort_id = #{effort_id}
        and lap = #{lap}
        and ((begin_split_id = #{split_id} and begin_bitkey = #{bitkey}) 
         or (end_split_id = #{split_id} and end_bitkey = #{bitkey}));
    SQL
  end

end
